//
//  VibeSelectionView.swift
//  EventsApp
//
//  Created by Шоу on 10/18/25.
//

import SwiftUI

struct VibeSelectionView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @StateObject private var vibeViewModel = VibeViewModel()
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("What are you into?")
                .headlineStyle()

            Text("Helps match you with events—and people—that share your interests.")
                .bodyTextStyle()

            ScrollView(.vertical) {
                WrapAroundLayout {
                    ForEach(vibeViewModel.displayVibes, id: \.id) { vibe in
                        VibeCapsule(
                            vibe: vibe,
                            isSelected: vibeViewModel.selectedVibes.contains(vibe)
                        ) {
                            vibeViewModel.toggleVibeSelection(vibe)
                        }
                    }
                }

                Spacer()
            }
            .scrollIndicators(.hidden)
        }
        .background(theme.colors.background)
        .onAppear {
            vibeViewModel.selectedVibes = userProfileViewModel.vibes  // Sync selected vibes with user profile.
        }
        .onChange(of: vibeViewModel.selectedVibes) { _, newVibes in
            userProfileViewModel.vibes = newVibes  // Update user profile when vibes change.
        }
    }
}
