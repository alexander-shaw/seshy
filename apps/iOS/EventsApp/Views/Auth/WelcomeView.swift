//
//  WelcomeView.swift
//  EventsApp
//
//  Created by Шоу on 10/16/25.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @Environment(\.theme) private var theme

    @State private var openAuth: Bool = false

    var body: some View {
        ZStack {
            // Background that fills entire space
            theme.colors.background
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: theme.spacing.small) {
                Spacer(minLength: theme.sizes.screenHeight / 3)

                Text("E v e n t s")
                    .displayTitleStyle()

                Spacer()

                PrimaryButton(icon: "chevron.up") {
                    openAuth = true
                }

                Spacer()

                Text(termsText())
                    .captionTextStyle()
                    .multilineTextAlignment(.center)
            }
            .padding([.top, .horizontal], theme.spacing.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $openAuth) {
            PhoneAuthView(userSession: userSession) {
                userSession.determineSessionState()
            }
        }
    }

    private func termsText() -> AttributedString {
        var string = AttributedString("By continuing, you agree to our\nterms of service and privacy policy.")

        // TODO: Create Terms of Service.
        if let range1 = string.range(of: "terms of service") {
            string[range1].link = URL(string: "https://example.com/terms")
            string[range1].foregroundColor = Color(theme.colors.offText)
            string[range1].font = .system(size: 12, weight: .bold)
        }

        // TODO: Create Privacy Policy.
        if let range2 = string.range(of: "privacy policy") {
            string[range2].link = URL(string: "https://example.com/privacy")
            string[range2].foregroundColor = Color(theme.colors.offText)
            string[range2].font = .system(size: 12, weight: .bold)
        }

        return string
    }
}


