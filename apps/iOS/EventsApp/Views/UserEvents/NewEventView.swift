//
//  NewEventView.swift
//  EventsApp
//
//  Created by Шоу on 10/20/25.
//

// TODO: Event name should be focused.

import SwiftUI
import CoreDomain

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @StateObject private var viewModel = UserEventViewModel()
    @State private var showPlaceSelection = false
    @State private var showTagSelector = false
    @State private var hasDrafts: Bool = false
    @State private var drafts: [UserEvent] = []
    
    private let repository: UserEventRepository = CoreDataUserEventRepository()

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.large) {
            // MARK: - BACK:
            TitleView(
                titleText: "",
                canGoBack: true,
                backIcon: "minus",
                trailing: {
                    if hasDrafts {
                        IconButton(icon: "doc.plaintext") {
                            // TODO: Show drafts as a context menu.
                            dismiss()
                        }
                    }
                }
            )

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: theme.spacing.medium) {
                    // MARK: - NAME:
                    TextFieldView(
                        placeholder: "Name",
                        text: $viewModel.name
                    )
                    .padding(.horizontal, theme.spacing.medium)

                    // MARK: - COLOR:
                    EventColorPicker(selectedColorHex: $viewModel.brandColor)  // No horizontal padding.

                    // MARK: - STARTS / ENDS:
                    EventStartEndView(startTime: $viewModel.startTime, endTime: $viewModel.endTime, durationMinutes: $viewModel.durationMinutes, isAllDay: $viewModel.isAllDay)
                        .padding(.horizontal, theme.spacing.medium)

                    // MARK: - PLACE:
                    HStack {
                        Image(systemName: "location.fill")
                            .iconStyle()
                            .foregroundStyle(theme.colors.accent)
                        
                        Text(viewModel.location.name)
                            .captionTitleStyle()
                        
                        Spacer()
                        
                        Button {
                            showPlaceSelection = true
                        } label: {
                            Image(systemName: "chevron.right")
                                .iconStyle()
                        }
                    }
                    .padding(.horizontal, theme.spacing.medium)
                    .padding(.vertical, theme.spacing.small)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, theme.spacing.medium)

                    Spacer()

                    // MARK: - SAVE / SEND:
                    HStack(spacing: theme.spacing.small) {
                        PrimaryButton(
                            title: "Save Draft",
                            isDisabled: !viewModel.isValid,
                            backgroundColor: AnyShapeStyle(theme.colors.surface)
                        ) {
                            Task {
                                await viewModel.saveEvent()
                                dismiss()
                            }
                        }

                        PrimaryButton(
                            title: "Send To",
                            isDisabled: !viewModel.isValid
                        ) {
                            Task {
                                await viewModel.publishEvent()
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.medium)

                    // MARK: - ERROR MESSAGES:
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .captionTitleStyle()
                            .foregroundColor(theme.colors.error)
                            .padding(.horizontal, theme.spacing.medium)
                    }
                }
                .padding(.vertical, theme.spacing.small)
            }
        }
        .background(theme.colors.background)
        .sheet(isPresented: $showPlaceSelection) {
            PlaceSelectionView(selectedPlace: $viewModel.location)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        }
        .sheet(isPresented: $showTagSelector) {
            // TODO: Event Tag Selection.
        }
        .onAppear {
            fetchDrafts()

            if viewModel.brandColor.isEmpty {
                viewModel.brandColor = "\(theme.colors.accent)"
            }
        }
    }
    
    private func fetchDrafts() {
        Task {
            do {
                let fetchedDrafts = try await repository.getDraftEvents()
                drafts = fetchedDrafts
                hasDrafts = !drafts.isEmpty
            } catch {
                print("Failed to fetch drafts: \(error)")
            }
        }
    }
}
