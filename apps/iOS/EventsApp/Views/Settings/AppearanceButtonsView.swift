//
//  AppearanceButtonsView.swift
//  EventsApp
//
//  Created on 10/25/25.
//

import SwiftUI
import CoreDomain

struct AppearanceButtonsView: View {
    @Binding var selectedMode: AppearanceMode
    let onSelect: (AppearanceMode) -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // System mode button
            appearanceButton(
                mode: .system,
                systemIcon: "gearshape.fill",
                label: "System",
                accessibilityLabel: "System appearance mode. Follows device settings."
            )
            
            // Light mode button
            appearanceButton(
                mode: .lightMode,
                systemIcon: "sun.max.fill",
                label: "Light",
                accessibilityLabel: "Light appearance mode"
            )
            
            // Dark mode button
            appearanceButton(
                mode: .darkMode,
                systemIcon: "moon.fill",
                label: "Dark",
                accessibilityLabel: "Dark appearance mode"
            )
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func appearanceButton(
        mode: AppearanceMode,
        systemIcon: String,
        label: String,
        accessibilityLabel: String
    ) -> some View {
        VStack(spacing: 8) {
            Button(action: {
                onSelect(mode)
            }) {
                ZStack {
                    Circle()
                        .fill(fillColor(for: mode))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: systemIcon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor(for: mode))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(mode == selectedMode ? .isSelected : [])
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func fillColor(for mode: AppearanceMode) -> Color {
        if mode == selectedMode {
            // Selected state
            switch mode {
            case .system:
                return systemButtonFill
            case .lightMode:
                return .yellow.opacity(0.3)
            case .darkMode:
                return .blue.opacity(0.3)
            }
        } else {
            // Unselected state
            return Color(UIColor.secondarySystemBackground)
        }
    }
    
    private var systemButtonFill: Color {
        // System button reflects current system style in real time
        let systemStyle = UITraitCollection.current.userInterfaceStyle
        if systemStyle == .dark {
            return Color(UIColor.systemBackground).opacity(0.5)
        } else {
            return Color(UIColor.label).opacity(0.1)
        }
    }
    
    private func iconColor(for mode: AppearanceMode) -> Color {
        switch mode {
        case .system:
            return .primary
        case .lightMode:
            return .orange
        case .darkMode:
            return .blue
        }
    }
}




