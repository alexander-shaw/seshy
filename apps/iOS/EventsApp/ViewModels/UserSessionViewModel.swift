//
//  UserSessionViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain

@MainActor
final class UserSessionViewModel: ObservableObject {
    @Published var appPhase: AppPhase = .splash
    @Published var currentUser: DeviceUser?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // ViewModels for different features.
    @Published var userProfileViewModel: UserProfileViewModel
    @Published var userLoginViewModel: UserLoginViewModel
    @Published var fingerprintViewModel: DeviceFingerprintViewModel
    
    private let context: NSManagedObjectContext
    private let userLoginRepository: UserLoginRepository
    private let deviceFingerprintRepository: DeviceFingerprintRepository
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, userLoginRepository: UserLoginRepository = CoreUserLoginRepository(), deviceFingerprintRepository: DeviceFingerprintRepository = CoreDeviceFingerprintRepository()) {
        self.context = context
        self.userLoginRepository = userLoginRepository
        self.deviceFingerprintRepository = deviceFingerprintRepository
        
        // Initialize child ViewModels.
        self.userProfileViewModel = UserProfileViewModel(context: context)
        self.userLoginViewModel = UserLoginViewModel(context: context)
        self.fingerprintViewModel = DeviceFingerprintViewModel(context: context)
    }
    
    func evaluateSessionState() async {
        isLoading = true
        errorMessage = nil
        
        print("EVALUATE SESSION STATE START:")

        // Ensure Core Data store is ready before proceeding.
        do {
            try await CoreDataStack.shared.waitForStore()
            print("Core Data store is ready.")
        } catch {
            print("Core Data store not ready:  \(error)")
            errorMessage = "Database initialization failed!  Restart the app!"
            appPhase = .welcome
            isLoading = false
            return
        }
        
        // Debug current state before evaluation.
        await debugCurrentState()
        
        do {
            // Check if device is locked out.
            let isLockedOut = try await deviceFingerprintRepository.isDeviceLockedOut()
            if isLockedOut.locked {
                print("Device is locked out.  Going to welcome.")
                appPhase = .welcome
                isLoading = false
                return
            }
            
            // Try to get current user using main context.
            if let user = try await userLoginRepository.getCurrentUser() {
                print("Current user found: \(user.id)")
                currentUser = user
                isAuthenticated = true
                
                // Check if user has complete profile using main context.
                let userProfileRepository = CoreUserProfileRepository()
                if let profile = try await userProfileRepository.getProfile(for: user) {
                    // Access the profile data safely by copying the values.
                    let profileDisplayName = profile.displayName
                    let profileDateOfBirth = profile.dateOfBirth
                    
                    print("Found profile:  displayName:  \(profileDisplayName) and dateOfBirth:  \(profileDateOfBirth?.description ?? "nil").")
                    print("Profile displayName.isEmpty:  \(profileDisplayName.isEmpty).")
                    print("Profile dateOfBirth is nil:  \(profileDateOfBirth == nil).")
                    print("Profile trimmed displayName:  \(profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)).")
                    print("Profile trimmed isEmpty:  \(profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).")

                    // Check if profile is complete.
                    let isDisplayNameValid = !profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let isDateOfBirthValid = profileDateOfBirth != nil
                    
                    if isDisplayNameValid && isDateOfBirthValid {
                        print("Profile complete.  Going to home.")
                        appPhase = .home
                    } else {
                        print("Profile incomplete.  Going to onboarding.")
                        print("  Display name valid:  \(isDisplayNameValid).")
                        print("  Date of birth valid:  \(isDateOfBirthValid).")
                        appPhase = .onboarding
                    }
                } else {
                    print("No profile found.  Going to onboarding.")
                    appPhase = .onboarding
                }
            } else {
                // No user found; need to authenticate.
                print("No current user found.  Going to welcome.")
                currentUser = nil
                isAuthenticated = false
                appPhase = .welcome
            }
        } catch {
            print("Error evaluating session state:  \(error).")
            errorMessage = "Failed to evaluate session state:  \(error.localizedDescription)."
            appPhase = .welcome
        }
        
        print("EVALUATE SESSION STATE END:")
        print("Final app phase:  \(appPhase).")
        print("Is authenticated:  \(isAuthenticated).")
        print("Current user:  \(currentUser?.id.uuidString ?? "nil").")

        isLoading = false
    }
    
    func signOut() async {
        do {
            // Clear current user session.
            try await userLoginRepository.clearCurrentUser()
            currentUser = nil
            isAuthenticated = false
            appPhase = .welcome
        } catch {
            errorMessage = "Failed to sign out:  \(error.localizedDescription)"
        }
    }

    // Signs out the user and deletes all locally stored user data.
    // Removes the DeviceUser and directly owned records and clears on-disk media cache/directories to ensure privacy.
    func signOutAndDeleteLocalData() async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            let context = CoreDataStack.shared.viewContext

            // Fetch the most recently logged-in user.
            let req: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
            req.predicate = NSPredicate(format: "login.lastLoginAt != nil")
            req.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
            req.fetchLimit = 1

            if let user = try context.fetch(req).first {
                // Manually delete related objects to avoid orphans due to Nullify rules.
                if let settings = user.settings { context.delete(settings) }
                if let profile = user.profile { context.delete(profile) }
                if let login = user.login { context.delete(login) }

                // Finally delete the user object.
                context.delete(user)
                try context.save()
            }

            // Best-effort: remove local media directory (images/videos) to clear cached user media.
            do {
                let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let mediaDir = documents.appendingPathComponent("Media", isDirectory: true)
                if FileManager.default.fileExists(atPath: mediaDir.path) {
                    try FileManager.default.removeItem(at: mediaDir)
                }
            } catch {
                // Non-fatal; log and continue.
                print("signOutAndDeleteLocalData | Failed to remove Media directory:  \(error)")
            }

            // Reset session state.
            currentUser = nil
            isAuthenticated = false
            appPhase = .welcome
        } catch {
            await MainActor.run { errorMessage = "Failed to sign out:  \(error.localizedDescription)" }
        }

        await MainActor.run { isLoading = false }
    }
    
    func setCurrentUser(_ user: DeviceUser) async {
        do {
            print("Setting current user:  \(user.id)")
            // Pass Core Data entity directly to repository.
            try await userLoginRepository.setCurrentUser(user)
            currentUser = user
            isAuthenticated = true
            
            // Re-evaluate session state to check profile completeness.
            await evaluateSessionState()
        } catch {
            print("ERROR: Failed to set current user:  \(error)")
            errorMessage = "Failed to set current user:  \(error.localizedDescription)"
        }
    }
    
    func updateAppPhase(_ phase: AppPhase) {
        appPhase = phase
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - METHODS EXPECTED BY VIEWS:
    func determineSessionState() {
        Task {
            await evaluateSessionState()
        }
    }
    
    func refreshSessionState() async {
        await evaluateSessionState()
    }
    
    func debugCurrentState() async {
        print("DEBUG: Current Session State:")
        print("App Phase:  \(appPhase)")
        print("Is Authenticated:  \(isAuthenticated)")
        print("Current User:  \(currentUser?.id.uuidString ?? "nil").")

        // Debug Core Data stack.
        print("Core Data Stack:")
        print("  View Context:  \(context)")
        print("  Persistent Store URL:  \(CoreDataStack.shared.container.persistentStoreDescriptions.first?.url?.absoluteString ?? "nil").")

        // Debug all users in database.
        do {
            let request: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
            let allUsers = try context.fetch(request)
            print("All users in database:  \(allUsers.count)")
            for user in allUsers {
                print("  User ID:  \(user.id) and lastLoginAt:  \(user.login?.lastLoginAt?.description ?? "nil").")
            }
        } catch {
            print("Error fetching all users:  \(error).")
        }
        
        // Debug all profiles in database.
        do {
            let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            let allProfiles = try context.fetch(request)
            print("All profiles in database:  \(allProfiles.count).")
            for profile in allProfiles {
                print("  Profile ID:  \(profile.id) and displayName:  \(profile.displayName) and dateOfBirth:  \(profile.dateOfBirth?.description ?? "nil").")
            }
        } catch {
            print("Error fetching all profiles:  \(error)")
        }
        
        if let user = currentUser {
            let userProfileRepository = CoreUserProfileRepository()
            do {
                if let profile = try await userProfileRepository.getProfile(for: user) {
                    // Access profile data safely.
                    let profileDisplayName = profile.displayName
                    let profileDateOfBirth = profile.dateOfBirth
                    print("Profile found:  \(profileDisplayName) and DOB:  \(profileDateOfBirth?.description ?? "nil").")
                } else {
                    print("No profile found for user.")
                }
            } catch {
                print("Error fetching profile:  \(error)")
            }
            
            // Also try to query directly from main context.
            let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            request.predicate = NSPredicate(format: "user == %@", user)
            request.fetchLimit = 1
            
            do {
                let profiles = try context.fetch(request)
                if let profile = profiles.first {
                    print("Direct context query found profile:  \(profile.displayName) and DOB:  \(profile.dateOfBirth?.description ?? "nil").")
                } else {
                    print("Direct context query found no profile.")
                }
            } catch {
                print("Direct context query error: \(error)")
            }
        }
    }
    
    func createProfileIfNeeded() async {
        guard let user = currentUser else {
            print("ERROR: No current user found for profile creation.")
            errorMessage = "No current user found."
            return
        }
        
        print("CREATE PROFILE START:")
        print("Creating profile for user:  \(user.id)")
        print("  displayName:  \(userProfileViewModel.displayNameInput).")
        print("  dateOfBirth:  \(userProfileViewModel.dateOfBirthInput?.description ?? "nil").")
        print("  bio:  \(userProfileViewModel.bioInput).")
        print("  tags count:  \(userProfileViewModel.vibes.count).")

        do {
            // Create or update user profile based on userProfileViewModel data.
            let userProfileRepository = CoreUserProfileRepository()
            
            // Check if profile already exists.
            if let existingProfile = try await userProfileRepository.getProfile(for: user) {
                print("Updating existing profile:  \(existingProfile.id).")
                // Update existing profile with data from userProfileViewModel.
                try await userProfileRepository.updateProfileWithForm(
                    existingProfile,
                    displayName: userProfileViewModel.displayNameInput,
                    bio: userProfileViewModel.bioInput,
                    dateOfBirth: userProfileViewModel.dateOfBirthInput,
                    showAge: userProfileViewModel.showAgeToggle,
                    genderCategory: userProfileViewModel.genderCategorySelection,
                    genderIdentity: userProfileViewModel.genderIdentityInput,
                    showGender: userProfileViewModel.showGenderToggle,
                    vibes: userProfileViewModel.vibes
                )
                print("Profile updated successfully.")
            } else {
                print("Creating new profile.")
                // Create new profile with form data.
                try await userProfileRepository.createProfileWithForm(
                    for: user,
                    displayName: userProfileViewModel.displayNameInput,
                    bio: userProfileViewModel.bioInput,
                    dateOfBirth: userProfileViewModel.dateOfBirthInput,
                    showAge: userProfileViewModel.showAgeToggle,
                    genderCategory: userProfileViewModel.genderCategorySelection,
                    genderIdentity: userProfileViewModel.genderIdentityInput,
                    showGender: userProfileViewModel.showGenderToggle,
                    vibes: userProfileViewModel.vibes
                )
                print("Profile created successfully.")
            }
            
            // Create default user settings if they do not exist.
            let userSettingsRepository = CoreUserSettingsRepository()
            do {
                _ = try await userSettingsRepository.getSettings(for: user)
                print("User settings already exist.")
            } catch {
                // Settings do not exist; create them.
                _ = try await userSettingsRepository.createSettings(for: user)
                print("Default user settings created.")
            }
            
            // Force save the main context to ensure persistence.
            try context.save()
            print("Main context saved to disk.")

            // Verify the profile was saved by checking it again.
            if let savedProfile = try await userProfileRepository.getProfile(for: user) {
                // Access the profile data safely by copying the values.
                let profileDisplayName = savedProfile.displayName
                let profileDateOfBirth = savedProfile.dateOfBirth
                
                print("Profile verification successful:")
                print("  Profile ID:  \(savedProfile.id).")
                print("  displayName:  \(profileDisplayName).")
                print("  dateOfBirth:  \(profileDateOfBirth?.description ?? "nil").")
                print("  displayName.isEmpty:  \(profileDisplayName.isEmpty).")
                print("  dateOfBirth is nil:  \(profileDateOfBirth == nil).")

                // Update current user reference and transition to home phase.
                currentUser = user
                appPhase = .home
                print("Transitioning to home phase.")
            } else {
                print("ERROR: Profile was not saved properly!")
                errorMessage = "Failed to save profile - please try again."
            }
            
        } catch {
            print("ERROR: Failed to create profile:  \(error).")
            errorMessage = "Failed to create profile:  \(error.localizedDescription)."
        }
    }
}
