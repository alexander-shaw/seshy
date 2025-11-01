//
//  PhoneAuthView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI
import Combine
import CoreDomain

enum PhoneAuthStep {
    case enterPhone, verifyCode
}

struct PhoneAuthView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.theme) private var theme
    var onFinished: () -> Void

    // Enter Phone:
    @State private var step: PhoneAuthStep = .enterPhone
    @State private var selectedCountry: CountryCode? = nil
    @State private var showCountrySelector = false
    @State private var phoneInputText: String = ""
    @State private var isSending = false

    // Verify Code:
    @State private var secondsRemaining = 60
    @State private var timerActive = true
    @State private var showOnboarding = false
    @State private var errorMessage: String?

    @State private var cancellables = Set<AnyCancellable>()

    private func startTimer() {
        secondsRemaining = 60
        timerActive = true

        Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .prefix(90)
            .sink { _ in
                if secondsRemaining > 0 {
                    secondsRemaining -= 1
                }
                if secondsRemaining == 0 {
                    timerActive = false
                }
            }
            .store(in: &cancellables)
    }

    var body: some View {
        VStack(spacing: theme.spacing.small) {
            switch step {
                case .enterPhone:
                    enterPhoneView

                case .verifyCode:
                    verifyCodeView
            }
        }
        .padding(.top, theme.spacing.medium)
        .padding(.horizontal, theme.spacing.medium)
        .padding(.bottom, theme.spacing.large / 2)
        .background(theme.colors.background)
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingStepsView(userSession: userSession)
        }
        .sheet(isPresented: $showCountrySelector) {
            CountrySelectorView(selectedCountry: $selectedCountry) { country in
                userSession.userLoginViewModel.callingCode = country.callingCode
                selectedCountry = country
            }
        }
        .onChange(of: step) { oldValue, newValue in
            // When returning to enterPhone step, restore the formatted phone number immediately.
            // This ensures the phone number is visible even after autofill and navigation.
            if newValue == .enterPhone && !userSession.userLoginViewModel.localNumber.isEmpty {
                let formatted = formatPhoneNumber(userSession.userLoginViewModel.localNumber)
                phoneInputText = formatted
            }
        }
    }
    
    private func formatPhoneNumber(_ digits: String) -> String {
        let clipped = String(digits.prefix(10))
        var formatted = ""
        for (index, digit) in clipped.enumerated() {
            if index == 3 || index == 6 { formatted += " " }
            formatted.append(digit)
        }
        return formatted
    }
    
    private func handlePhoneInputChange(_ newValue: String) {
        // If empty and we already have a valid number, don't clear it.
        // This prevents clearing when TextFieldView temporarily clears displayedText.
        if newValue.isEmpty {
            // Only allow clearing if user manually deleted everything.
            // Don't clear if we have a valid number already.
            if userSession.userLoginViewModel.isValidPhoneNumber {
                return
            }
            // If empty and no valid number, allow clearing.
            userSession.userLoginViewModel.localNumber = ""
            phoneInputText = ""
            return
        }
        
        // Parse the input to extract country code and local number.
        // newValue may contain + and country code (from autofill) or just digits (from manual typing).
        let parsed = userSession.userLoginViewModel.parsePhoneNumber(newValue)
        
        // Debug: log what we're parsing.
        print("DEBUG: Parsing '\(newValue)' -> callingCode: '\(parsed.callingCode)', localNumber: '\(parsed.localNumber)'")
        
        // Update calling code if detected.
        if parsed.callingCode != userSession.userLoginViewModel.callingCode {
            userSession.userLoginViewModel.callingCode = parsed.callingCode
            // Find and set selected country.
            if let country = CountryCodeData.countryCodes.first(where: { $0.callingCode == parsed.callingCode }) {
                selectedCountry = country
            }
        }
        
        // Store previous local number for auto-advance check.
        let previousLocalNumber = userSession.userLoginViewModel.localNumber
        
        // Update local number - use parsed value if available, otherwise try fallback.
        if !parsed.localNumber.isEmpty {
            // Normal case: parsing succeeded.
            userSession.userLoginViewModel.localNumber = parsed.localNumber
        } else {
            // Fallback: if parsing returned empty but input has content, try extracting just digits.
            let digits = newValue.filter(\.isNumber)
            if digits.count >= 10 {
                // If we have 11 digits starting with 1, it's US/Canada with country code.
                if digits.count == 11 && digits.hasPrefix("1") {
                    userSession.userLoginViewModel.localNumber = String(digits.dropFirst())
                } else if digits.count >= 10 {
                    // Take last 10 digits as local number.
                    userSession.userLoginViewModel.localNumber = String(digits.suffix(10))
                } else {
                    userSession.userLoginViewModel.localNumber = digits
                }
            } else if !digits.isEmpty {
                // Keep partial input if less than 10 digits.
                userSession.userLoginViewModel.localNumber = digits
            }
        }
        
        // Format the local number correctly.
        let formatted = formatPhoneNumber(userSession.userLoginViewModel.localNumber)
        
        // Immediately update displayed text to show only formatted local number (no country code visible).
        // This prevents showing country code in the text field when autofill happens.
        if phoneInputText != formatted {
            phoneInputText = formatted
        }
        
        // Check if we should auto-advance immediately (no delay).
        // Only advance if local number changed and is now valid.
        if userSession.userLoginViewModel.localNumber.count == 10 && previousLocalNumber.count != 10 && !isSending {
            // Immediate auto-advance - formatting already applied above.
            handleAutoAdvance()
        }
    }
    
    private func handleAutoAdvance() {
        // Guard against double-sending: check if already sending or already on verify step.
        guard userSession.userLoginViewModel.isValidPhoneNumber,
              !isSending,
              step == .enterPhone else { return }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                try await userSession.userLoginViewModel.prepareOTP()
                await MainActor.run {
                    // Double-check we're still on enter phone step before advancing.
                    if step == .enterPhone {
                        step = .verifyCode
                        startTimer()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isSending = false
            }
        }
    }

    private var enterPhoneView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Spacer()
            
            Text("What's your number?")
                .headlineStyle()

            Text("One quick code and you’re good to go.")
                .bodyTextStyle()

            Spacer()

            HStack(alignment: .bottom, spacing: theme.spacing.small) {
                Button {
                    showCountrySelector = true
                } label: {
                    if let country = selectedCountry {
                        Text(country.callingCode)
                            .titleStyle()
                    } else {
                        Text(userSession.userLoginViewModel.callingCode)
                            .titleStyle()
                    }
                }
                .padding(.vertical, 8)
                .overlay(
                    VStack {
                        Spacer()
                        Capsule()
                            .fill(theme.colors.mainText)
                            .frame(height: 2)
                    }
                )

                TextFieldView(
                    placeholder: "000 000 0000",
                    specialType: .phoneNumber,
                    text: $phoneInputText
                )
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .submitLabel(.next)
                .onChange(of: phoneInputText) { oldValue, newValue in
                    handlePhoneInputChange(newValue)
                }
            }

            Text("By continuing, you agree to receive a one-time text message.  Message & data rates may apply.")
                .captionTextStyle()

            Spacer()

            HStack {
                Spacer()

                // TODO: Add !userSession.fingerprintViewModel.shouldAllowLogin().
                PrimaryButton(title: "Next", isDisabled: !userSession.userLoginViewModel.isValidPhoneNumber || isSending) {
                    handleAutoAdvance()
                }

                Spacer()
            }
        }
        .onAppear {
            // Initialize country code from locale if not already set.
            if selectedCountry == nil {
                let defaultCountry = CountryCodeData.defaultCountryCode()
                selectedCountry = defaultCountry
                userSession.userLoginViewModel.callingCode = defaultCountry.callingCode
            } else {
                // Restore selectedCountry from current calling code when going back.
                if selectedCountry?.callingCode != userSession.userLoginViewModel.callingCode {
                    if let country = CountryCodeData.countryCodes.first(where: { $0.callingCode == userSession.userLoginViewModel.callingCode }) {
                        selectedCountry = country
                    }
                }
            }
            
            // Always restore phoneInputText with formatted local number if it exists.
            // This ensures the formatted phone number is visible when returning to this view.
            if !userSession.userLoginViewModel.localNumber.isEmpty {
                let formatted = formatPhoneNumber(userSession.userLoginViewModel.localNumber)
                phoneInputText = formatted
            }
        }
    }

    private var verifyCodeView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            HStack {
                Spacer()
                IconButton(icon: "chevron.left") {
                    userSession.userLoginViewModel.verificationCode = ""
                    // Restore formatted phone number before changing step to ensure it's ready.
                    if !userSession.userLoginViewModel.localNumber.isEmpty {
                        phoneInputText = formatPhoneNumber(userSession.userLoginViewModel.localNumber)
                    }
                    step = .enterPhone
                }
            }

            Spacer()

            Text("Enter verification code")
                .headlineStyle()

            Text("This may take a moment.")
                .bodyTextStyle()

            Spacer()

            VerificationCodeView(code: $userSession.userLoginViewModel.verificationCode)

            if !timerActive {
                Button("Resend Code") {
                    isSending = true
                    errorMessage = nil
                    Task {
                        do {
                            try await userSession.userLoginViewModel.prepareOTP()
                            await MainActor.run {
                                startTimer()
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = error.localizedDescription
                            }
                        }
                        await MainActor.run {
                            isSending = false
                        }
                    }
                }
                .foregroundStyle(theme.colors.accent)
                .captionTextStyle()
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(theme.colors.error)
            }

            Spacer()

            HStack {
                Spacer()

                PrimaryButton(title: "Verify", isDisabled: userSession.userLoginViewModel.verificationCode.count != 6 || isSending) {
                    isSending = true
                    errorMessage = nil
                    Task {
                        do {
                            try await userSession.userLoginViewModel.verifyOTP()
                            // After successful verification, transition to onboarding phase
                            await MainActor.run {
                                userSession.appPhase = .onboarding
                            }
                            onFinished()
                        } catch {
                            await MainActor.run {
                                errorMessage = "Verification failed:  \(error.localizedDescription)"
                            }
                        }
                        await MainActor.run {
                            isSending = false
                        }
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            startTimer()
        }
    }
}
