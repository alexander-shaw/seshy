//
//  UserLoginViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import Combine
import CoreData
import SwiftUI

@MainActor
final class UserLoginViewModel: ObservableObject {
    @Published var callingCode: String = "+1"
    @Published var localNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var isVerifying: Bool = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private let userLoginRepository: UserLoginRepository
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, userLoginRepository: UserLoginRepository = CoreUserLoginRepository()) {
        self.context = context
        self.userLoginRepository = userLoginRepository
        
        // Initializes calling code from device locale!
        let defaultCountry = CountryCodeData.defaultCountryCode()
        self.callingCode = defaultCountry.callingCode
    }
    
    // Checks if the current phone number is valid (10 digits).
    var isValidPhoneNumber: Bool {
        localNumber.count == 10
    }
    
    // Parses a phone number that may include country code.
    // Handles formats including: "+1 7651234567", "+17651234567", "17651234567", "7651234567".
    // Parameter input: Raw phone number input that may include country code.
    // Returns: Tuple of (callingCode: String, localNumber: String).
    func parsePhoneNumber(_ input: String) -> (callingCode: String, localNumber: String) {
        // Removes all non-digit characters (except +).
        let cleaned = input.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
        
        // If starts with +, try to match country codes.
        if cleaned.hasPrefix("+") {
            // Sort country codes by length (longest first) to avoid partial matches.
            let sortedCodes = CountryCodeData.countryCodes.sorted { country1, country2 in
                let code1Digits = country1.callingCode.replacingOccurrences(of: "+", with: "")
                let code2Digits = country2.callingCode.replacingOccurrences(of: "+", with: "")
                return code1Digits.count > code2Digits.count
            }
            
            for country in sortedCodes {
                let codeDigits = country.callingCode.replacingOccurrences(of: "+", with: "")
                if cleaned.hasPrefix("+\(codeDigits)") {
                    let remaining = String(cleaned.dropFirst(codeDigits.count + 1))  // +1 for the +
                    let localDigits = remaining.filter(\.isNumber)
                    return (country.callingCode, localDigits)
                }
            }
        }
        
        // If starts with 1 and has 11 digits, might be US/Canada with leading 1.
        let digits = cleaned.filter(\.isNumber)
        if digits.hasPrefix("1") && digits.count == 11 && callingCode == "+1" {
            return ("+1", String(digits.dropFirst()))
        }
        
        // Default: assume current calling code, return all digits as local.
        let localDigits = digits.filter(\.isNumber)
        return (callingCode, localDigits)
    }
    
    // Processes a phone number input, extracting country code if present.
    // Updates callingCode and localNumber based on parsed input.
    // Parameter input: Raw phone number input.
    func processPhoneInput(_ input: String) {
        let parsed = parsePhoneNumber(input)
        callingCode = parsed.callingCode
        localNumber = parsed.localNumber
    }
    
    func prepareOTP() async throws {
        isVerifying = true
        errorMessage = nil
        
        do {
            // Implementation for preparing OTP.
            // This would typically send OTP to the phone number.
            print("Preparing OTP for \(callingCode)\(localNumber)")
            // Simulate API call.
            // TODO: Trigger real API call.
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
                // Success: creates a user; proceeds to onboarding.
                try await createUserAfterVerification()
            } else {
                throw NSError(domain: "InvalidCode", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code."])
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
        
        print("User created successfully.  Transitioning to onboarding phase.")
    }
    
    func clearError() {
        errorMessage = nil
    }
}
