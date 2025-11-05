//
//  AppearanceButtonsView.swift
//  EventsApp
//
//  Created on 10/25/25.
//

// TODO: Refactor this code.

import SwiftUI
import CoreDomain

struct AppearanceButtonsView: View {
    @Binding var selectedMode: AppearanceMode
    let onSelect: (AppearanceMode) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.small) {
            Spacer()
            
            // System mode button.
            appearanceButton(
                mode: .system,
                systemIcon: "gearshape.fill",
                label: "System"
            )
            
            // Light mode button.
            appearanceButton(
                mode: .lightMode,
                systemIcon: "sun.max.fill",
                label: "Light"
            )
            
            // Dark mode button.
            appearanceButton(
                mode: .darkMode,
                systemIcon: "moon.fill",
                label: "Dark"
            )
            
            Spacer()
        }
        .padding(.vertical, theme.spacing.small)
    }
    
    @ViewBuilder
    private func appearanceButton(
        mode: AppearanceMode,
        systemIcon: String,
        label: String
    ) -> some View {
        VStack(spacing: theme.spacing.small) {
            Button(action: {
                onSelect(mode)
            }) {
                ZStack {
                    Circle()
                        .fill(fillColor(for: mode))
                        .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)

                    Image(systemName: systemIcon)
                        .iconStyle()
                }
            }
            
            Text(label)
                .captionTitleStyle()
        }
    }
    
    private func fillColor(for mode: AppearanceMode) -> Color {
        if mode == selectedMode {
            // Selected state.
            switch mode {
                case .system:
                    return systemButtonFill
                case .lightMode:
                    return theme.colors.mainText
                case .darkMode:
                    return theme.colors.surface
            }
        } else {
            // Unselected state.
            return theme.colors.offText
        }
    }
    
    private var systemButtonFill: Color {
        // System button reflects current system style in real time.
        let systemStyle = UITraitCollection.current.userInterfaceStyle
        if systemStyle == .dark {
            return theme.colors.surface
        } else {
            return theme.colors.mainText
        }
    }
}
