//
//  TagSelectionView.swift
//  EventsApp
//
//  Created by Шоу on 10/18/25.
//

import SwiftUI

struct TagSelectionView: View {
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    @StateObject private var tagViewModel = TagViewModel()
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("What are you into?")
                .headlineStyle()

            Text("Helps match you with events—and people—that share your interests.")
                .bodyTextStyle()

            ScrollView(.vertical) {
                WrapAroundLayout {
                    ForEach(tagViewModel.displayTags, id: \.id) { tag in
                        TagCapsule(
                            tag: tag,
                            isSelected: tagViewModel.selectedTags.contains(tag)
                        ) {
                            tagViewModel.toggleTagSelection(tag)
                        }
                    }
                }

                Spacer()
            }
            .scrollIndicators(.hidden)
        }
        .background(theme.colors.background)
        .onAppear {
            tagViewModel.selectedTags = userProfileViewModel.tags  // Sync selected tags with user profile.
        }
        .onChange(of: tagViewModel.selectedTags) { _, newTags in
            userProfileViewModel.tags = newTags  // Update user profile when tags change.
        }
    }
}
