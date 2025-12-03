//
//  JoinEventSheet.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

// Join Event Sheet - Shows ticket selection for events with multiple tickets

import SwiftUI

struct JoinEventSheet: View {
    let event: EventItem
    let currentUserID: UUID?
    
    @StateObject private var viewModel: JoinEventViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    @State private var showConfirmation = false
    
    init(event: EventItem, currentUserID: UUID? = nil) {
        self.event = event
        self.currentUserID = currentUserID
        _viewModel = StateObject(wrappedValue: JoinEventViewModel(event: event, currentUserID: currentUserID))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("Select a Ticket")
                .headlineStyle()
                .padding(.horizontal, theme.spacing.medium)
                .padding(.top, theme.spacing.medium)
            
            ScrollView {
                VStack(spacing: theme.spacing.small) {
                    ForEach(viewModel.availableTickets, id: \.id) { ticket in
                        Button {
                            withAnimation {
                                viewModel.selectTicket(ticket)
                            }
                        } label: {
                            HStack(spacing: theme.spacing.large) {
                                VStack(alignment: .leading, spacing: theme.spacing.small) {
                                    // Price as title
                                    Text(ticket.formattedPrice)
                                        .bodyTextStyle()
                                    
                                    // Name as description
                                    Text(ticket.name)
                                        .captionTextStyle()
                                        .foregroundStyle(theme.colors.offText)
                                }
                                .padding(.leading, theme.spacing.small / 2)
                                
                                Spacer()
                                
                                SelectionIcon(isSelected: viewModel.selectedTicket?.id == ticket.id)
                            }
                            .padding(theme.spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: theme.spacing.medium)
                                    .fill(theme.colors.surface)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacing.medium)
            }
            
            if let selectedTicket = viewModel.selectedTicket {
                PrimaryButton(
                    title: selectedTicket.priceCents > 0 ? "Purchase" : "Join",
                    isDisabled: viewModel.isProcessing
                ) {
                    if selectedTicket.priceCents > 0 {
                        // Show confirmation for paid tickets
                        showConfirmation = true
                    } else {
                        // Free ticket - join directly
                        Task {
                            await handleJoinOrPurchase()
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.medium)
                .padding(.bottom, theme.spacing.medium)
            }
        }
        .background(theme.colors.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .confirmationDialog(
            "Confirm Purchase",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Confirm") {
                Task {
                    await handleJoinOrPurchase()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let ticket = viewModel.selectedTicket {
                Text("Purchase \(ticket.name) for \(ticket.formattedPrice)?")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private func handleJoinOrPurchase() async {
        do {
            try await viewModel.processPurchase()
            // Dismiss sheet after successful purchase and join
            dismiss()
        } catch {
            // Error handled by viewModel.errorMessage - don't dismiss on failure
        }
    }
}
