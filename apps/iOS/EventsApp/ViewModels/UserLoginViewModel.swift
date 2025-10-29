//
//  UserLoginViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages user authentication and login flow.
// Provides a reactive interface for SwiftUI views to handle authentication including:
// - Phone number verification;
// - SMS code verification;
// - User session management; and
// - Integration with Core Data persistence layer.

import Foundation
import Combine
import CoreData
import SwiftUI
import CoreDomain

@MainActor
final class UserLoginViewModel: ObservableObject {
    @Published var callingCode: String = "+1"
    @Published var localNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var isVerifying: Bool = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private let userLoginRepository: UserLoginRepository
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, userLoginRepository: UserLoginRepository = CoreDataUserLoginRepository()) {
        self.context = context
        self.userLoginRepository = userLoginRepository
    }
    
    func prepareOTP() async throws {
        isVerifying = true
        errorMessage = nil
        
        do {
            // Implementation for preparing OTP.
            // This would typically send OTP to the phone number.
            print("Preparing OTP for \(callingCode)\(localNumber)")
            // Simulate API call.
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second.
        } catch {
            errorMessage = "Failed to send OTP:  \(error.localizedDescription)"
            throw error
        }
        
        isVerifying = false
    }
    
    func verifyOTP() async throws {
        isVerifying = true
        errorMessage = nil
        
        do {
            // Implementation for verifying OTP.
            // This would typically verify the code with the server.
            print("Verifying OTP: \(verificationCode)")
            // Simulate API call.
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second.

            // For now, just simulate successful verification.
            if verificationCode.count == 6 {
                // Success - create a user and proceed to onboarding.
                try await createUserAfterVerification()
            } else {
                throw NSError(domain: "InvalidCode", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"])
            }
        } catch {
            errorMessage = "Failed to verify OTP:  \(error.localizedDescription)"
            throw error
        }
        
        isVerifying = false
    }
    
    private func createUserAfterVerification() async throws {
        // Create a new user after successful verification.
        let phoneNumber = "\(callingCode)\(localNumber)"
        print("Creating user for phone number: \(phoneNumber)")
        
        // Create a new DeviceUser.
        let newUser = try await userLoginRepository.createUserLogin(phoneNumber: phoneNumber)
        
        // Set as current user.
        try await userLoginRepository.setCurrentUser(newUser)
        
        print("User created successfully, transitioning to onboarding phase")
    }
    
    func clearError() {
        errorMessage = nil
    }
}
