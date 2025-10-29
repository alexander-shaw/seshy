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
    
    // Local state for tracking changes
    @State private var originalAppearanceMode: AppearanceMode
    @State private var originalPreferredUnits: Units
    
    init(viewModel: UserSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _originalAppearanceMode = State(initialValue: viewModel.appearanceMode)
        _originalPreferredUnits = State(initialValue: viewModel.preferredUnits)
    }
    
    // Computed property to detect if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        viewModel.appearanceMode != originalAppearanceMode ||
        viewModel.preferredUnits != originalPreferredUnits
    }
    
    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                unitsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Revert changes
                        viewModel.appearanceMode = originalAppearanceMode
                        viewModel.preferredUnits = originalPreferredUnits
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.persist()
                        // Update originals
                        originalAppearanceMode = viewModel.appearanceMode
                        originalPreferredUnits = viewModel.preferredUnits
                        dismiss()
                    }
                    .disabled(!hasUnsavedChanges)
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    
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
    
    // MARK: - Units Section
    
    private var unitsSection: some View {
        Section {
            HStack {
                Text("Units")
                
                Spacer()
                
                Menu {
                    Button(action: {
                        viewModel.selectUnits(.imperial)
                    }) {
                        HStack {
                            Text("Imperial")
                            if viewModel.preferredUnits == .imperial {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.selectUnits(.metric)
                    }) {
                        HStack {
                            Text("Metric")
                            if viewModel.preferredUnits == .metric {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.selectUnits(nil) // Use system default
                    }) {
                        HStack {
                            Text("System Default")
                            if viewModel.preferredUnits == viewModel.systemMeasurementDefault {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
            Text(selectedUnitsLabel)
                .foregroundColor(.secondary)
                .accessibilityLabel("Units selection: \(selectedUnitsLabel)")
                .accessibilityHint("Tap to change units")
                }
            }
            
            Text(subtitleText)
                .font(.caption)
                .foregroundColor(.secondary)
        } footer: {
            if viewModel.preferredUnits != viewModel.systemMeasurementDefault {
                Text("Currently using \(viewModel.preferredUnits == .imperial ? "Imperial" : "Metric") units")
                    .font(.caption2)
            }
        }
    }
    
    private var selectedUnitsLabel: String {
        switch viewModel.preferredUnits {
        case .imperial:
            return "Imperial"
        case .metric:
            return "Metric"
        }
    }
    
    private var subtitleText: String {
        let systemDefault = viewModel.systemMeasurementDefault == .imperial ? "Imperial" : "Metric"
        let usingSystem = viewModel.preferredUnits == viewModel.systemMeasurementDefault
        
        return usingSystem
            ? "Following system (default: \(systemDefault))"
            : "System default: \(systemDefault)"
    }
}

