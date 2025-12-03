//
//  IconButton.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public enum IconButtonStyle {
    case primary
    case secondary
}

public struct IconButton: View {
    @Environment(\.theme) private var theme
    public let icon: String
    public let style: IconButtonStyle
    public var action: () -> Void

    public init(icon: String, style: IconButtonStyle = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            if style == .primary {
                ZStack {
                    Circle()
                        .fill(theme.colors.surface)
                        .opacity(0.75)

                    Image(systemName: icon)
                        .iconStyle()
                }
                .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                .contentShape(Circle())
                .compositingGroup()
            } else if style == .secondary {
                Image(systemName: icon)
                    .foregroundStyle(theme.colors.offText)
                    .bodyTextStyle()
                    .frame(maxWidth: theme.sizes.iconButton, maxHeight: theme.sizes.iconButton)
                    .contentShape(Circle())
            }
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.medium)
    }
}

// LATER: .blendMode(.multiply)
