//
//  LocationConsentStepView.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import SwiftUI

struct LocationStepView: View {
    @ObservedObject var userSession: UserSessionViewModel
    @ObservedObject private var locationViewModel = LocationViewModel.shared
    @Environment(\.theme) private var theme
    
    var body: some View {
        ZStack {
            // Base map view - onboarding version (no dismiss button)
            LocationOnboardingView()
            
            // Permission overlay when needed
            if locationViewModel.currentStep == .permission {
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: theme.spacing.medium) {
                        Text("Share your location")
                            .headlineStyle()

                        Text("We use your location to show nearby events.  We never share it.")
                            .fontWeight(.bold)
                            .bodyTextStyle()
                            .fixedSize(horizontal: false, vertical: true)

                        LocationPermissionView(
                            onManualEntryRequested: {
                                locationViewModel.currentStep = .manual
                            }
                        )
                    }
                    .padding(theme.spacing.large)
                    .background(theme.colors.surface.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: theme.spacing.medium))
                    .padding(.horizontal, theme.spacing.medium)
                    .padding(.bottom, theme.spacing.large)
                    
                    Spacer()
                }
                .background(Color.black.opacity(0.3))
                .transition(.opacity)
            }
        }
        .onAppear {
            locationViewModel.updateUserSession(userSession)
            locationViewModel.startLocationFlow()
        }
    }
}

