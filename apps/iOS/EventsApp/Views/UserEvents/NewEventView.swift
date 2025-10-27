//
//  NewEventView.swift
//  EventsApp
//
//  Created by Шоу on 10/20/25.
//

import SwiftUI
import CoreDomain

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @StateObject private var viewModel = UserEventViewModel()
    @State private var showPlaceSelection = false
    @State private var showTagSelector = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: theme.spacing.large) {
                    // MARK: - BACK:
                    HStack(spacing: theme.spacing.small) {
                        IconButton(icon: "minus") {
                            dismiss()
                        }

                        Spacer()
                    }
                    .padding(.horizontal, theme.spacing.medium)

                    VStack(alignment: .leading, spacing: theme.spacing.medium) {
                        // MARK: - NAME:
                        TextFieldView(
                            placeholder: "Name",
                            text: $viewModel.name
                        )
                        .padding(.horizontal, theme.spacing.medium)

                        // MARK: - COLOR:
                        EventColorPicker(selectedColorHex: $viewModel.brandColor)
                    }

                    // MARK: - ERROR MESSAGES:
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .captionTitleStyle()
                            .foregroundColor(theme.colors.error)
                            .padding(.horizontal, theme.spacing.medium)
                    }

                    // MARK: - SAVE / SEND:
                    HStack(spacing: theme.spacing.small) {
                        Spacer()  // TODO: Replace with a "Save Draft" button.

                        // TODO: Refactor the PrimaryButton() to have a more dynamic width.
                        PrimaryButton(title: "Send To", isDisabled: viewModel.isValid) {
                            // TODO: viewModel.createEvent()
                            dismiss()
                        }
                    }
                    .padding(.horizontal, theme.spacing.medium)
                }
                .padding(.vertical, theme.spacing.small)
            }
        }
        .background(theme.colors.background)
        .sheet(isPresented: $showPlaceSelection) {
            // TODO: Place Selection.
        }
        .sheet(isPresented: $showTagSelector) {
            // TODO: Event Tag Selection.
        }
    }
}
