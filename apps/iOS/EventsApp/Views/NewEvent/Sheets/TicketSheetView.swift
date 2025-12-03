//
//  TicketSheetView.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import SwiftUI

struct TicketSheetView: View {
    @EnvironmentObject private var userSession: UserSessionViewModel
    @StateObject private var viewModel = TicketViewModel()
    @State private var showCreateForm = false
    @State private var newTicketName = ""
    @State private var newTicketPrice = ""
    @State private var isCreating = false
    @State private var createErrorMessage: String?
    @State private var priceConflictMessage: String?
    
    var selectedTickets: Set<Ticket>
    var onSelect: (Set<Ticket>) -> Void
    var onDone: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider().foregroundStyle(theme.colors.surface)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        // Your Tickets Section
                        if !viewModel.userTickets.isEmpty {
                            userTicketsSection
                        }
                        
                        // Price Conflict Message
                        if let message = priceConflictMessage {
                            priceConflictBanner(message: message)
                        }
                        
                        // Create New Section
                        createTicketSection
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Tickets")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
        .task {
            await loadUserTickets()
        }
        .sheet(isPresented: $showCreateForm) {
            createTicketForm
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
        if selectedTickets.isEmpty {
            return "No tickets selected"
        }
        
        let count = selectedTickets.count
        let totalPrice = selectedTickets.reduce(0) { $0 + $1.priceCents }
        
        if count == 1 {
            let ticket = selectedTickets.first!
            return "\(ticket.name) · \(ticket.formattedPrice)"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            let totalDollars = Double(totalPrice) / 100.0
            let totalString = formatter.string(from: NSNumber(value: totalDollars)) ?? "$0"
            return "\(count) tickets · \(totalString) total"
        }
    }
    
    // MARK: - Your Tickets Section
    
    private var userTicketsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Your Tickets")
            
            VStack(spacing: theme.spacing.small) {
                ForEach(viewModel.userTickets) { ticket in
                    ticketRow(ticket: ticket)
                }
            }
        }
    }
    
    private func ticketRow(ticket: Ticket) -> some View {
        let isSelected = selectedTickets.contains(ticket)
        let hasPriceConflict = !isSelected && selectedTickets.contains { $0.priceCents == ticket.priceCents }
        
        return Button {
            toggleTicket(ticket)
        } label: {
            HStack(spacing: theme.spacing.medium) {
                Image(systemName: "ticket.fill")
                    .foregroundStyle(
                        hasPriceConflict
                            ? theme.colors.offText.opacity(0.5)
                            : (isSelected ? theme.colors.accent : theme.colors.offText)
                    )
                    .iconStyle()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.name)
                        .font(theme.typography.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(
                            hasPriceConflict
                                ? theme.colors.offText.opacity(0.5)
                                : theme.colors.mainText
                        )
                    
                    Text(ticket.formattedPrice)
                        .font(theme.typography.caption)
                        .foregroundStyle(
                            hasPriceConflict
                                ? theme.colors.offText.opacity(0.3)
                                : theme.colors.offText
                        )
                }
                
                Spacer()
                
                if hasPriceConflict {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .iconStyle()
                } else {
                    SelectionIcon(isSelected: isSelected)
                }
            }
            .padding(theme.spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.spacing.medium)
                    .fill(
                        hasPriceConflict
                            ? theme.colors.surface.opacity(0.2)
                            : (isSelected ? theme.colors.surface.opacity(0.5) : theme.colors.surface.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.spacing.medium)
                            .stroke(
                                hasPriceConflict
                                    ? Color.orange.opacity(0.3)
                                    : (isSelected ? theme.colors.accent.opacity(0.5) : Color.clear),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.light)
        .disabled(hasPriceConflict)
    }
    
    // MARK: - Price Conflict Banner
    
    private func priceConflictBanner(message: String) -> some View {
        HStack(spacing: theme.spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .iconStyle()
            
            Text(message)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.mainText)
            
            Spacer()
        }
        .padding(theme.spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: theme.spacing.medium)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.spacing.medium)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Create Ticket Section
    
    private var createTicketSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Create New")
            
            Button {
                showCreateForm = true
            } label: {
                HStack(spacing: theme.spacing.medium) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.colors.accent)
                        .iconStyle()
                    
                    Text("Add Ticket")
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
    
    // MARK: - Create Ticket Form
    
    private var createTicketForm: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        VStack(alignment: .leading, spacing: theme.spacing.small) {
                            Text("Ticket Name")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.offText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            TextFieldView(
                                placeholder: "Enter ticket name",
                                specialType: .enterName,
                                text: $newTicketName,
                                autofocus: true
                            )
                        }
                        .padding(theme.spacing.medium)
                        
                        VStack(alignment: .leading, spacing: theme.spacing.small) {
                            Text("Price (Optional)")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.offText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            TextFieldView(
                                placeholder: "Enter price or leave empty for free",
                                specialType: .enterDollars,
                                text: $newTicketPrice,
                                autofocus: false
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
                        newTicketName = ""
                        newTicketPrice = ""
                        createErrorMessage = nil
                    }
                    
                    PrimaryButton(title: "Create") {
                        Task {
                            await createTicket()
                        }
                    }
                    .disabled(newTicketName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
                .padding(theme.spacing.medium)
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("New Ticket")
                        .font(theme.typography.headline)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserTickets() async {
        await viewModel.loadAllTickets()
    }
    
    private func toggleTicket(_ ticket: Ticket) {
        var updated = selectedTickets
        if updated.contains(ticket) {
            updated.remove(ticket)
            priceConflictMessage = nil
        } else {
            // Check for price conflict
            let hasPriceConflict = updated.contains { $0.priceCents == ticket.priceCents }
            if hasPriceConflict {
                priceConflictMessage = "A ticket with price \(ticket.formattedPrice) is already selected. Each selected ticket must have a unique price."
                // Clear message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    priceConflictMessage = nil
                }
                return
            }
            updated.insert(ticket)
            priceConflictMessage = nil
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            onSelect(updated)
        }
    }
    
    private func createTicket() async {
        let trimmedName = newTicketName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            createErrorMessage = "Ticket name cannot be empty"
            return
        }
        
        // Allow empty price for free tickets (defaults to 0)
        let price = newTicketPrice.isEmpty ? 0.0 : (Double(newTicketPrice) ?? 0.0)
        guard price >= 0 else {
            createErrorMessage = "Price must be greater than or equal to 0"
            return
        }
        
        isCreating = true
        createErrorMessage = nil
        
        do {
            let newTicket = try await viewModel.createTicket(name: trimmedName, priceDollars: price)
            // Check for price conflict before auto-selecting
            let priceCents = Int64(price * 100)
            let hasPriceConflict = selectedTickets.contains { $0.priceCents == priceCents }
            
            if !hasPriceConflict {
                // Auto-select the newly created ticket only if no price conflict
                var updated = selectedTickets
                updated.insert(newTicket)
                onSelect(updated)
            }
            // Reload list
            await loadUserTickets()
            // Close form
            showCreateForm = false
            newTicketName = ""
            newTicketPrice = ""
        } catch {
            createErrorMessage = "Failed to create ticket: \(error.localizedDescription)"
        }
        
        isCreating = false
    }
}
