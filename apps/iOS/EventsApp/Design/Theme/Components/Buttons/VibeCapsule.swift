//
//  VibeCapsule.swift
//  EventsApp
//
//  Created by Шоу on 10/19/25.
//

import SwiftUI

public struct VibeCapsule: View {
    @Environment(\.theme) private var theme
    
    public let vibe: Vibe
    public let isSelected: Bool
    public let onTap: () -> Void
    
    public init(vibe: Vibe, isSelected: Bool, onTap: @escaping () -> Void) {
        self.vibe = vibe
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            Text(vibe.name)
                .font(theme.typography.caption)
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
