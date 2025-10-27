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

    // Phone:
    @State private var step: PhoneAuthStep = .enterPhone
    @State private var selectedCountry: (flag: String, name: String, countryCode2: String, countryCode3: String, callingCode: String)? = nil
    @State private var isSending = false

    // Verify:
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
    }

    private var enterPhoneView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Spacer()
            
            Text("What's your number?")
                .headlineStyle()

            Text("Let's verify you're really you.")
                .bodyTextStyle()

            Spacer()

            HStack(alignment: .bottom, spacing: theme.spacing.small) {
                Menu {
                    ForEach(countryCodes, id: \.name) { country in
                        Button("\(country.flag)  \(country.callingCode)  \(country.name)") {
                            userSession.userLoginViewModel.callingCode = country.callingCode
                            selectedCountry = country
                        }
                    }
                } label: {
                    if let country = selectedCountry {
                        Text("\(country.callingCode)")
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
                    text: $userSession.userLoginViewModel.localNumber
                )
                .textContentType(.telephoneNumber)
                .keyboardType(.numberPad)
                .submitLabel(.next)
            }

            Text("By continuing, you agree to receive a one-time text message.  Message & data rates may apply.")
                .captionTextStyle()

            Spacer()

            HStack {
                Spacer()

                // TODO: Add !userSession.fingerprintViewModel.shouldAllowLogin().
                PrimaryButton(title: "Next", isDisabled: userSession.userLoginViewModel.localNumber.count != 10 || isSending) {
                    isSending = true
                    errorMessage = nil
                    Task {
                        do {
                            try await userSession.userLoginViewModel.prepareOTP()
                            await MainActor.run {
                                step = .verifyCode
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

                Spacer()
            }
        }
    }

    private var verifyCodeView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            HStack {
                Spacer()
                IconButton(icon: "chevron.left") {
                    userSession.userLoginViewModel.verificationCode = ""
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

// An array of every country: with flag, name, country codes (ISO 2-letter & 3-letter), and calling code.
let countryCodes: [(flag: String, name: String, countryCode2: String, countryCode3: String, callingCode: String)] = [
    ("🇺🇸", "United States", "US", "USA", "+1"),
    ("🇦🇷", "Argentina", "AR", "ARG", "+54"),
    ("🇦🇺", "Australia", "AU", "AUS", "+61"),
    ("🇦🇹", "Austria", "AT", "AUT", "+43"),
    ("🇧🇩", "Bangladesh", "BD", "BGD", "+880"),
    ("🇧🇪", "Belgium", "BE", "BEL", "+32"),
    ("🇧🇷", "Brazil", "BR", "BRA", "+55"),
    ("🇧🇬", "Bulgaria", "BG", "BGR", "+359"),
    ("🇨🇦", "Canada", "CA", "CAN", "+1"),
    ("🇨🇳", "China", "CN", "CHN", "+86"),
    ("🇭🇷", "Croatia", "HR", "HRV", "+385"),
    ("🇨🇾", "Cyprus", "CY", "CYP", "+357"),
    ("🇨🇿", "Czech Republic", "CZ", "CZE", "+420"),
    ("🇩🇰", "Denmark", "DK", "DNK", "+45"),
    ("🇪🇪", "Estonia", "EE", "EST", "+372"),
    ("🇪🇹", "Ethiopia", "ET", "ETH", "+251"),
    ("🇫🇮", "Finland", "FI", "FIN", "+358"),
    ("🇫🇷", "France", "FR", "FRA", "+33"),
    ("🇩🇪", "Germany", "DE", "DEU", "+49"),
    ("🇬🇷", "Greece", "GR", "GRC", "+30"),
    ("🇭🇺", "Hungary", "HU", "HUN", "+36"),
    ("🇮🇳", "India", "IN", "IND", "+91"),
    ("🇮🇩", "Indonesia", "ID", "IDN", "+62"),
    ("🇮🇪", "Ireland", "IE", "IRL", "+353"),
    ("🇮🇹", "Italy", "IT", "ITA", "+39"),
    ("🇰🇿", "Kazakhstan", "KZ", "KAZ", "+7"),
    ("🇱🇻", "Latvia", "LV", "LVA", "+371"),
    ("🇱🇹", "Lithuania", "LT", "LTU", "+370"),
    ("🇱🇺", "Luxembourg", "LU", "LUX", "+352"),
    ("🇲🇹", "Malta", "MT", "MLT", "+356"),
    ("🇲🇽", "Mexico", "MX", "MEX", "+52"),
    ("🇳🇱", "Netherlands", "NL", "NLD", "+31"),
    ("🇳🇬", "Nigeria", "NG", "NGA", "+234"),
    ("🇵🇰", "Pakistan", "PK", "PAK", "+92"),
    ("🇵🇱", "Poland", "PL", "POL", "+48"),
    ("🇵🇹", "Portugal", "PT", "PRT", "+351"),
    ("🇷🇴", "Romania", "RO", "ROU", "+40"),
    ("🇷🇺", "Russia", "RU", "RUS", "+7"),
    ("🇸🇰", "Slovakia", "SK", "SVK", "+421"),
    ("🇸🇮", "Slovenia", "SI", "SVN", "+386"),
    ("🇪🇸", "Spain", "ES", "ESP", "+34"),
    ("🇸🇪", "Sweden", "SE", "SWE", "+46")
]
