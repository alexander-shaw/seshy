//
//  Theme.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI

// MARK: - PRIMARY BUTTON:
struct PrimaryButton: View {
    let themeColor: Color
    let icon: String?
    let title: String?
    let isDisabled: Bool
    let action: () -> Void

    init(
        themeColor: Color = Theme.ColorPalette.accent,
        icon: String? = nil,
        title: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.themeColor = themeColor
        self.icon = icon
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: Theme.Spacing.elements / 2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(Theme.Font.icon)
                }
                if let title = title, !title.isEmpty {
                    Text(title)
                        .font(Theme.Font.body)
                }
            }
            .foregroundStyle(isDisabled ? Theme.ColorPalette.offText : Theme.ColorPalette.mainText)
            .padding(.vertical, Theme.Spacing.buttonVertical)
            .padding(.horizontal, Theme.Spacing.buttonHorizontal)
            .frame(maxWidth: .infinity)
            .background(isDisabled ? AnyShapeStyle(Theme.ColorPalette.surface) : AnyShapeStyle(themeColor))
            .clipShape(Capsule())
        }
        .disabled(isDisabled)
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(style: .medium)
    }
}

// MARK: - ICON BUTTON:
struct IconButton: View {
    let backgroundColor: Color
    let icon: String
    let action: () -> Void

    init(
        backgroundColor: Color = Theme.ColorPalette.surface,
        icon: String,
        action: @escaping () -> Void
    ) {
        self.backgroundColor = backgroundColor
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Base tint:
                Circle()
                    .fill(backgroundColor)
                
                // Surface on top:
                Circle()
                    .fill(Theme.ColorPalette.surface)
                    .opacity(0.25)
                    .blendMode(.multiply)

                // Icon is rendered last, so it’s visibly on top.
                Image(systemName: icon)
                    .foregroundStyle(Theme.ColorPalette.mainText)
                    .font(Theme.Font.icon)
            }
            .frame(width: Theme.Size.iconButton, height: Theme.Size.iconButton)
            .contentShape(Circle())
            .compositingGroup()  // Nicer edges when blending/animating.
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(style: .medium)
    }
}

// MARK: - COLLAPSE EFFECT:
extension Theme {
    struct SpringAnimation {
        static let buttonResponse: CGFloat = 0.45  // 0.3 is quick.  1.0 is slower and smoother.
        static let buttonDamping: CGFloat = 0.45  // 0.6 is moderate.  1.0 is no bounce & no smoothness.
        static let buttonBounce: CGFloat = 0.90  // Scale effect when the button is pressed.
    }
}

struct CollapseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.SpringAnimation.buttonBounce : 1.0)  // Scale up when pressed.
            .animation(.spring(response: Theme.SpringAnimation.buttonResponse, dampingFraction: Theme.SpringAnimation.buttonDamping), value: configuration.isPressed)  // Smooth animation for scaling.
    }
}
