//
//  OnboardingStepsView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI
import Combine

struct OnboardingStep: Identifiable {
    let id: String
    let view: AnyView
    let isAccessible: () -> Bool
}

struct OnboardingStepsView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) private var theme

    @State private var currentIndex: Int = 0
    @State private var isStepAccessible: Bool = false
    @State private var showErrorMessage = false
    @State private var showDateOfBirthConfirmation = false

    // MARK: - ORDER:
    // (1) DISPLAY NAME
    // (2) DATE OF BIRTH
    // (3) GENDER (OPTIONAL)
    // (4) PROFILE PICTURES
    // (5) SELECT TAGS
    // (6) TURN ON PUSH NOTIFICATIONS
    // (7) TURN ON LOCATION
    var steps: [OnboardingStep] {
        [
            OnboardingStep(
                id: "displayName",
                view: AnyView(DisplayNameStepView(userSession: userSession)),
                isAccessible: { userSession.userProfileViewModel.isValidDisplayName }
            ),

            OnboardingStep(
                id: "dateOfBirth",
                view: AnyView(DateOfBirthStepView(userSession: userSession)),
                isAccessible: { userSession.userProfileViewModel.isValidDateOfBirth }
            ),

            OnboardingStep(
                id: "gender",
                view: AnyView(GenderStepView(userSession: userSession)),
                isAccessible: { true }  // Gender is optional, always accessible
            ),

            OnboardingStep(
                id: "profilePictures",
                view: AnyView(ProfilePicturesStepView(userSession: userSession)),
                isAccessible: { userSession.userProfileViewModel.hasAtLeastOneMedia }
            ),

            OnboardingStep(
                id: "tags",
                view: AnyView(
                    VibeSelectionView().environmentObject(userSession.userProfileViewModel)
                ),
                isAccessible: { userSession.userProfileViewModel.isValidVibes }
            ),

            // TODO: Turn on notifications here.

            OnboardingStep(
                id: "location",
                view: AnyView(LocationStepView(userSession: userSession)),
                isAccessible: { true }
            )
        ]
    }

    var body: some View {
        let currentStep = steps[currentIndex]

        return VStack(alignment: .center, spacing: theme.spacing.small) {
            Spacer()

            currentStep.view
                .padding(.top, theme.spacing.large)
                .padding(.horizontal, theme.spacing.medium)
                .environment(\.showErrorMessage, showErrorMessage)
                .onReceive(userSession.userProfileViewModel.objectWillChange) {
                    isStepAccessible = steps[currentIndex].isAccessible()
                }

            PrimaryButton(
                title: currentIndex < steps.count - 1 ? "Next" : "Done",
                isDisabled: currentIndex < steps.count - 1 ? !isStepAccessible : !userSession.userProfileViewModel.isProfileComplete
            ) {
                if currentIndex < steps.count - 1 {
                    if isStepAccessible {
                        showErrorMessage = false
                        
                        // Show confirmation alert for date of birth step.
                        if steps[currentIndex].id == "dateOfBirth" {
                            showDateOfBirthConfirmation = true
                        } else {
                            currentIndex += 1
                        }
                    } else {
                        showErrorMessage = true
                    }
                } else {
                    // Last step: only reachable if full profile is valid.
                    Task { await userSession.createProfileIfNeeded() }
                }
            }
            .padding(.bottom, theme.spacing.small)
            .alert("Confirm Your Age", isPresented: $showDateOfBirthConfirmation) {
                Button("Edit", role: .cancel) {
                    // Stay on the current step.
                }
                Button("Continue") {
                    currentIndex += 1
                }
            } message: {
                if let age = calculatedAge {
                    Text("This cannot be changed later.  You are \(age) years old?")
                }
            }
        }
        .background(theme.colors.background)
        .statusBarHidden(true)
        .environment(\.showErrorMessage, showErrorMessage)
        .onReceive(userSession.userProfileViewModel.objectWillChange) {
            isStepAccessible = steps[currentIndex].isAccessible()
        }
        .onAppear {
            isStepAccessible = steps[currentIndex].isAccessible()
        }
    }
    
    // MARK: - COMPUTED PROPERTIES:
    private var calculatedAge: Int? {
        guard let dateOfBirth = userSession.userProfileViewModel.dateOfBirthInput else {
            return nil
        }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }
}

struct ShowErrorMessageKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var showErrorMessage: Bool {
        get { self[ShowErrorMessageKey.self] }
        set { self[ShowErrorMessageKey.self] = newValue }
    }
}
