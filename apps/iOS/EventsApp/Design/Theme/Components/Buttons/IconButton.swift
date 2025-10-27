//
//  IconButton.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct IconButton: View {
    @Environment(\.theme) private var theme
    public let icon: String
    public var action: () -> Void

    public init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(theme.colors.surface)

                Circle()
                    .fill(theme.colors.surface)
                    .opacity(0.25)
                    .blendMode(.multiply)

                Image(systemName: icon)
                    .iconStyle()
            }
            .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
            .contentShape(Circle())
            .compositingGroup()
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.medium)
    }
}
