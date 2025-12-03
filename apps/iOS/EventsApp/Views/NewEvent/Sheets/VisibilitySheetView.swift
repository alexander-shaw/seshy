//
//  VisibilitySheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

struct VisibilitySheetView: View {
    @State private var selectedVisibility: EventVisibility
    var onChange: (EventVisibility) -> Void
    var onDone: () -> Void

    @Environment(\.theme) private var theme

    init(selected: EventVisibility, onChange: @escaping (EventVisibility) -> Void, onDone: @escaping () -> Void) {
        _selectedVisibility = State(initialValue: selected)
        self.onChange = onChange
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                    .foregroundStyle(theme.colors.surface.opacity(0.5))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        sectionHeader("Who can see this event?")
                        
                        VStack(spacing: theme.spacing.small) {
                            ForEach(EventVisibility.allCases) { visibility in
                                visibilityCard(visibility: visibility)
                            }
                        }
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Visibility")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("Preview")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.offText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            HStack(spacing: theme.spacing.small) {
                Image(systemName: selectedVisibility.systemName)
                    .foregroundStyle(theme.colors.accent)
                    .iconStyle()
                
                Text(selectedVisibility.title)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.mainText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
    
    // MARK: - Visibility Card
    
    private func visibilityCard(visibility: EventVisibility) -> some View {
        let isSelected = visibility == selectedVisibility
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedVisibility = visibility
                onChange(visibility)
            }
        } label: {
            HStack(spacing: theme.spacing.large) {
                Image(systemName: visibility.systemName)
                    .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.offText)
                    .iconStyle()
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: theme.spacing.small) {
                    Text(visibility.title)
                        .font(theme.typography.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(theme.colors.mainText)

                    Text(visibility.description)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.offText)
                }
                
                Spacer()

                SelectionIcon(isSelected: isSelected)
            }
            .padding(theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.spacing.medium)
                    .fill(isSelected ? theme.colors.surface.opacity(0.5) : theme.colors.surface.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.spacing.medium)
                            .stroke(
                                isSelected ? theme.colors.accent.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.light)
    }
    
    // MARK: - Section Header Helper
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.offText)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
