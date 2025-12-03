//
//  SettingsView.swift
//  EventsApp
//
//  Created on 10/25/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @StateObject private var viewModel: UserSettingsViewModel
    @EnvironmentObject private var userSession: UserSessionViewModel
    @EnvironmentObject private var userProfileViewModel: UserProfileViewModel

    // Local state for tracking changes.
    @State private var originalAppearanceMode: AppearanceMode
    @State private var originalMediaItems: [MediaItem] = []
    @State private var isSaving: Bool = false
    @State private var showDisplayNameSheet = false
    @State private var showGenderSheet = false
    
    init(viewModel: UserSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _originalAppearanceMode = State(initialValue: viewModel.appearanceMode)
    }
    
    // Computed property to detect if there are unsaved changes.
    private var hasUnsavedChanges: Bool {
        viewModel.appearanceMode != originalAppearanceMode || hasMediaChanges
    }
    
    private var hasMediaChanges: Bool {
        let currentIDs = Set(userProfileViewModel.editingMediaItems.map { $0.id })
        let originalIDs = Set(originalMediaItems.map { $0.id })
        
        // Check if media count or IDs changed.
        if currentIDs != originalIDs {
            return true
        }
        
        // Check if positions changed.
        for (index, item) in userProfileViewModel.editingMediaItems.enumerated() {
            if let originalItem = originalMediaItems.first(where: { $0.id == item.id }),
               originalItem.position != Int16(index) {
                return true
            }
        }
        
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TitleView(
                titleText: "Settings",
                canGoBack: true,
                backIcon: "chevron.left",
                onBack: {
                    Task {
                        await saveAndDismiss()
                    }
                }
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.medium) {
                    Section("Edit Profile") {
                        profileMediaSection
                    }
                    .captionTitleStyle()

                    // MARK: - LOGOUT:
                    Button(role: .destructive) {
                        Task { @MainActor in
                            await userSession.signOutAndDeleteLocalData()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: theme.spacing.small) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .iconStyle()
                            Text("Log Out")
                                .bodyTextStyle()
                        }
                    }
                }
                .padding(theme.spacing.medium)
            }

            Spacer(minLength: 0)
        }
        .background(theme.colors.background)
        .task {
            // Load media for editing when view appears.
            await refreshProfileAndMedia()
        }
        .onChange(of: viewModel.appearanceMode) { oldValue, newValue in
            // Save appearance changes immediately.
            viewModel.persist()
        }
    }
    
    // MARK: - REFRESH:
    private func refreshProfileAndMedia() async {
        await userProfileViewModel.refreshProfile(for: userSession.currentUser)
        userProfileViewModel.loadMediaForEditing()

        // Update original media items to reflect current state.
        originalMediaItems = userProfileViewModel.editingMediaItems
    }
    
    // MARK: - SAVE AND DISMISS:
    private func saveAndDismiss() async {
        isSaving = true
        
        // Save appearance settings.
        viewModel.persist()
        
        // Save media changes when back button is tapped.
        // Clear editing items when dismissing.
        do {
            print("SettingsView | Saving media changes before dismiss.")
            try await userProfileViewModel.saveMediaChanges(for: userSession.currentUser, clearEditingItems: true)
            print("SettingsView | Media changes saved successfully.")

            // Reload profile to ensure ProfileView sees the changes.
            await userProfileViewModel.loadProfile(for: userSession.currentUser)
        } catch {
            // Continue to dismiss even if media save fails.
            print("SettingsView | Failed to save media changes: \(error)")
        }
        
        isSaving = false
        dismiss()
    }
    
    // MARK: - PROFILE MEDIA:
    private var profileMediaSection: some View {
        MediaGridPicker(
            mediaItems: $userProfileViewModel.editingMediaItems,
            maxItems: 4,
            onMediaChanged: {
                // Update positions when media changes.
                updateMediaPositions()
            }
        )
    }
    
    private func updateMediaPositions() {
        var updatedItems: [MediaItem] = []
        for (index, item) in userProfileViewModel.editingMediaItems.enumerated() {
            var updatedItem = item
            updatedItem.position = Int16(index)
            updatedItems.append(updatedItem)
        }
        userProfileViewModel.editingMediaItems = updatedItems
    }
}
