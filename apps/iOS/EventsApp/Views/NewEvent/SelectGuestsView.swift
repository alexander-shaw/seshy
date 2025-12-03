//
//  SelectGuestsView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

struct SelectGuestsView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    let tabManager: TabManager?
    
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    @State private var isPublishing = false
    @State private var hasPublished = false
    
    var body: some View {
        VStack(spacing: 0) {
            TitleView(
                titleText: "Guests",
                canGoBack: true,
                backIcon: "chevron.left",
                onBack: {
                    dismiss()
                }
            )
            
            // Blank content area for now.
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom button for publishing.
            HStack(spacing: theme.spacing.medium) {
                Spacer()
                
                PrimaryButton(
                    title: "Publish",
                    isDisabled: isPublishing || viewModel.isSaving || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasPublished,
                    action: {
                        // Prevent multiple taps
                        guard !isPublishing && !hasPublished else { return }
                        
                        // Validate before publishing - check isPublishable (name, startTime, place)
                        guard viewModel.isPublishable else {
                            // Show error if required fields are missing
                            validationErrorMessage = "Please fill in all required fields (name, time, and place) before publishing."
                            showValidationError = true
                            return
                        }
                        
                        // Set publishing state immediately to prevent duplicate taps
                        isPublishing = true
                        
                        Task {
                            await viewModel.publishEvent()
                            
                            // Check if publish was successful
                            if viewModel.errorMessage == nil {
                                hasPublished = true
                                
                                // Navigate back to previous tab instead of just dismissing
                                await MainActor.run {
                                    if let tabManager = tabManager {
                                        tabManager.select(tabManager.lastTab)
                                    } else {
                                        dismiss()
                                    }
                                }
                            } else {
                                // Reset publishing state on error so user can retry
                                isPublishing = false
                            }
                        }
                    }
                )
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.bottom, theme.spacing.medium)
            .background(theme.colors.background)
        }
        .background(theme.colors.background)
        .navigationBarHidden(true)
        .alert("Cannot Publish", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationErrorMessage)
        }
    }
}
