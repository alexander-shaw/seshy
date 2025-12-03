//
//  VibeCapsule.swift
//  EventsApp
//
//  Created by Шоу on 10/19/25.
//

import SwiftUI

/// Capsule-style toggle that can represent any selectable tag or menu chip.
public struct VibeCapsule: View {
    @Environment(\.theme) private var theme

    private let title: String
    private let icon: String?
    public let isSelected: Bool
    public let onTap: () -> Void

    /// General-purpose initializer for any selectable chip.
    public init(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.onTap = onTap
    }

    /// Convenience initializer to keep existing Vibe-based usages working.
    public init(vibe: Vibe, isSelected: Bool, onTap: @escaping () -> Void) {
        self.init(title: vibe.name, isSelected: isSelected, onTap: onTap)
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let icon {
                    IconButton(icon: icon, style: .secondary) {}
                }

                Text(title)
                    .font(theme.typography.caption)
            }
            .foregroundStyle(isSelected ? theme.colors.mainText : theme.colors.offText)
            .padding(.vertical, theme.spacing.small / 2)
            .padding(.horizontal, theme.spacing.small / 2)
            .background(
                Capsule()
                    .fill(.clear)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? theme.colors.accent : theme.colors.surface, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.light)
    }
}
