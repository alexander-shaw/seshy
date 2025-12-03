//
//  LocationSheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI
import CoreData

struct LocationSheetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var userSession: UserSessionViewModel
    @StateObject private var viewModel = PlaceViewModel()
    @State private var showCreateForm = false
    @State private var newPlaceName = ""
    @State private var isCreating = false
    @State private var createErrorMessage: String?

    @Environment(\.theme) private var theme

    var selectedPlace: Place?
    var onSelect: (Place) -> Void
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                    .foregroundStyle(theme.colors.surface.opacity(0.5))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        // Your Places Section
                        if !viewModel.userPlaces.isEmpty {
                            userPlacesSection
                        }
                        
                        // Create New Section
                        createPlaceSection
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Location")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
        .task {
            await loadUserPlaces()
        }
        .sheet(isPresented: $showCreateForm) {
            createPlaceForm
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
            
            Text(previewText)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.mainText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
    
    private var previewText: String {
        if let place = selectedPlace {
            return place.name
        }
        return "No location selected"
    }
    
    // MARK: - Your Places Section
    
    private var userPlacesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Your Places")
            
            VStack(spacing: theme.spacing.small) {
                ForEach(viewModel.userPlaces) { place in
                    placeRow(place: place)
                }
            }
        }
    }
    
    private func placeRow(place: Place) -> some View {
        let isSelected = place.id == selectedPlace?.id
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onSelect(place)
            }
        } label: {
            HStack(spacing: theme.spacing.medium) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.offText)
                    .iconStyle()
                
                Text(place.name)
                    .font(theme.typography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(theme.colors.mainText)
                
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
    
    // MARK: - Create Place Section
    
    private var createPlaceSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Create New")
            
            Button {
                showCreateForm = true
            } label: {
                HStack(spacing: theme.spacing.medium) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.colors.accent)
                        .iconStyle()
                    
                    Text("Add Place")
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.colors.mainText)
                    
                    Spacer()
                }
                .padding(theme.spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: theme.spacing.medium)
                        .fill(theme.colors.surface.opacity(0.3))
                )
            }
            .buttonStyle(CollapseButtonStyle())
            .hapticFeedback(.light)
        }
    }
    
    // MARK: - Section Header Helper
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.offText)
            .textCase(.uppercase)
            .tracking(0.5)
    }
    
    // MARK: - Create Place Form
    
    private var createPlaceForm: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        VStack(alignment: .leading, spacing: theme.spacing.small) {
                            Text("Place Name")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.offText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            TextFieldView(
                                placeholder: "Enter place name",
                                specialType: .enterName,
                                text: $newPlaceName,
                                autofocus: true
                            )
                        }
                        .padding(theme.spacing.medium)
                        
                        if let errorMessage = createErrorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(errorMessage)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(.horizontal, theme.spacing.medium)
                        }
                    }
                }
                
                HStack(spacing: theme.spacing.medium) {
                    PrimaryButton(
                        title: "Cancel",
                        backgroundColor: AnyShapeStyle(theme.colors.surface)
                    ) {
                        showCreateForm = false
                        newPlaceName = ""
                        createErrorMessage = nil
                    }
                    
                    PrimaryButton(title: "Create") {
                        Task {
                            await createPlace()
                        }
                    }
                    .disabled(newPlaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
                .padding(theme.spacing.medium)
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("New Place")
                        .font(theme.typography.headline)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserPlaces() async {
        await viewModel.loadAllPlaces()
    }
    
    private func createPlace() async {
        let trimmedName = newPlaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            createErrorMessage = "Place name cannot be empty"
            return
        }
        
        isCreating = true
        createErrorMessage = nil
        
        do {
            let newPlace = try await viewModel.createPlace(name: trimmedName)
            // Auto-select the newly created place
            onSelect(newPlace)
            // Reload list
            await loadUserPlaces()
            // Close form
            showCreateForm = false
            newPlaceName = ""
        } catch {
            createErrorMessage = "Failed to create place: \(error.localizedDescription)"
        }
        
        isCreating = false
    }
}
