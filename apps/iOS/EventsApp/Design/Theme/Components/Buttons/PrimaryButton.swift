//
//  PrimaryButton.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct PrimaryButton: View {
    @Environment(\.theme) private var theme

    public let icon: String?
    public let title: String?
    public let isDisabled: Bool
    public var action: () -> Void

    public init(icon: String? = nil, title: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                        .iconStyle()
                }
                if let title = title, !title.isEmpty {
                    Text(title)
                        .buttonTextStyle()
                }
            }
            .foregroundStyle(isDisabled ? theme.colors.offText : theme.colors.mainText)
            .padding(.vertical, theme.spacing.medium)
            .frame(minWidth: theme.sizes.screenWidth / 2)
            .background(isDisabled ? AnyShapeStyle(theme.colors.surface) : AnyShapeStyle(theme.colors.accent))
            .clipShape(Capsule())
        }
        .disabled(isDisabled)
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.medium)
    }
}
