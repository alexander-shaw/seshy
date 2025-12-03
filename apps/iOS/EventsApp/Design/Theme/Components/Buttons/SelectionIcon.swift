//
//  SelectionIcon.swift
//  EventsApp
//
//  Created by Шоу on 12/1/25.
//

import SwiftUI

// A reusable icon component for option selection states.
// Supports both standard selection (selected/unselected) and expandable options (like "other").
public struct SelectionIcon: View {
    @Environment(\.theme) private var theme
    
    let isSelected: Bool
    let isExpandable: Bool
    
    public init(isSelected: Bool, isExpandable: Bool = false) {
        self.isSelected = isSelected
        self.isExpandable = isExpandable
    }
    
    public var body: some View {
        Image(systemName: iconName)
            .imageScale(.large)
            .symbolRenderingMode(.palette)
            .foregroundStyle(theme.colors.mainText, foregroundColor)
            .buttonTextStyle()
    }
    
    private var iconName: String {
        if isExpandable {
            return "plus.circle"
        } else if isSelected {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var foregroundColor: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(theme.colors.accent)
        } else {
            return AnyShapeStyle(theme.colors.mainText)
        }
    }
}