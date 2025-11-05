//
//  SettingsView.swift
//  EventsApp
//
//  Created on 10/25/25.
//

import SwiftUI
import CoreDomain

struct SettingsView: View {
    @StateObject private var viewModel: UserSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var userSession: UserSessionViewModel

    // Local state for tracking changes.
    @State private var originalAppearanceMode: AppearanceMode
    
    init(viewModel: UserSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _originalAppearanceMode = State(initialValue: viewModel.appearanceMode)
    }
    
    // Computed property to detect if there are unsaved changes.
    private var hasUnsavedChanges: Bool {
        viewModel.appearanceMode != originalAppearanceMode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TitleView(
                titleText: "Settings",
                canGoBack: true,
                backIcon: "minus",
                onBack: {
                    // Revert changes.
                    viewModel.appearanceMode = originalAppearanceMode
                    dismiss()
                }, trailing: {
                    IconButton(icon: "checkmark") {
                        viewModel.persist()

                        // Update originals.
                        originalAppearanceMode = viewModel.appearanceMode
                        dismiss()
                    }
                    // .disabled(!hasUnsavedChanges)
                }
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.medium) {
                    appearanceSection

                    Divider()
                        .foregroundStyle(theme.colors.surface)

                    logoutSection
                }
                .padding(.vertical, theme.spacing.small)
                .padding(.horizontal, theme.spacing.medium)
            }

            Spacer(minLength: 0)
        }
        .background(theme.colors.background)
    }
    
    // MARK: - APPEARANCE:
    private var appearanceSection: some View {
        Section("Appearance") {
            AppearanceButtonsView(
                selectedMode: $viewModel.appearanceMode,
                onSelect: { mode in
                    viewModel.selectAppearanceMode(mode)
                }
            )
        }
    }

    // MARK: - LOG OUT:
    private var logoutSection: some View {
        Section("Account") {
            Button(role: .destructive) {
                Task { @MainActor in
                    await userSession.signOutAndDeleteLocalData()
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
            }
        }
    }
}
