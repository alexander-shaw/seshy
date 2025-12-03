//
//  CapacitySheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

struct CapacitySheetView: View {
    @State private var capacityText: String
    var onChange: (Int?) -> Void
    var onDone: () -> Void

    @Environment(\.theme) private var theme

    init(maxCapacity: Int, onChange: @escaping (Int?) -> Void, onDone: @escaping () -> Void) {
        let initialValue = maxCapacity <= 0 ? "" : String(maxCapacity)
        _capacityText = State(initialValue: initialValue)
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
                
                VStack(spacing: theme.spacing.medium) {
                    Spacer()

                    TextFieldView(
                        placeholder: "Max Capacity",
                        specialType: .bigNumber,
                        text: $capacityText,
                        autofocus: true
                    )

                    Spacer()

                    HStack(spacing: theme.spacing.medium) {
                        PrimaryButton(title: "Unlimited", backgroundColor: AnyShapeStyle(theme.colors.surface)) {
                            capacityText = ""
                            onChange(nil)
                            onDone()
                        }

                        PrimaryButton(title: "Done") {
                            handleDone()
                        }
                    }
                }
                .padding(.vertical, theme.spacing.small)
                .padding(.horizontal, theme.spacing.medium)
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Capacity")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: handleDone)
                }
            }
        }
        .onChange(of: capacityText) { oldValue, newValue in
            if let capacity = Int(newValue), capacity > 0 {
                onChange(capacity)
            } else if newValue.isEmpty {
                onChange(nil)
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
            
            Text(previewText)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.mainText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
    
    private var previewText: String {
        if let capacity = Int(capacityText), capacity > 0 {
            return "\(capacity) people"
        }
        return "Unlimited"
    }
    
    private func handleDone() {
        if let capacity = Int(capacityText), capacity > 0 {
            onChange(capacity)
        } else {
            onChange(nil)
        }
        onDone()
    }
}
