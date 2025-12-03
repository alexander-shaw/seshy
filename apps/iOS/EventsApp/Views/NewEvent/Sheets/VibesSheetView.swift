//
//  VibesSheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

struct VibesSheetView: View {
    var selectedVibes: Set<String>
    var onToggle: (String) -> Void
    var onDone: () -> Void

    @Environment(\.theme) private var theme
    @StateObject private var vibeViewModel = VibeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                    .foregroundStyle(theme.colors.surface.opacity(0.5))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        sectionHeader("Select Vibes")
                        
                        WrapAroundLayout {
                            ForEach(displayVibes, id: \.self) { vibeName in
                                VibeCapsule(
                                    title: vibeName,
                                    isSelected: selectedVibes.contains(vibeName)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        onToggle(vibeName)
                                    }
                                }
                            }
                        }
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Vibes")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
        .task {
            await vibeViewModel.loadActiveVibes()
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
            
            if selectedVibes.isEmpty {
                Text("No vibes selected")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.mainText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.small) {
                        ForEach(Array(selectedVibes).sorted(), id: \.self) { vibeName in
                            Text(vibeName)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.mainText)
                                .padding(.horizontal, theme.spacing.small)
                                .padding(.vertical, theme.spacing.small / 2)
                                .background(
                                    Capsule()
                                        .fill(theme.colors.accent.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(theme.colors.accent, lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
    
    // MARK: - Display Vibes
    
    private var displayVibes: [String] {
        // Use vibes from VibeViewModel if available, otherwise fallback to suggestions
        if !vibeViewModel.displayVibes.isEmpty {
            return vibeViewModel.displayVibes.map { $0.name }
        }
        // Fallback suggestions
        return [
            "House",
            "Techno",
            "Disco",
            "R&B",
            "Afrobeats",
            "Open Decks",
            "Pool",
            "Sunset",
            "Afterhours",
            "Wellness",
            "Costumes",
            "Live Set"
        ]
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
