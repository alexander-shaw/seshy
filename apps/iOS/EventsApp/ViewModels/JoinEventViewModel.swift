//
//  JoinEventViewModel.swift
//  EventsApp
//
//  Created by Auto on 1/2/25.
//

import Foundation
import Combine

@MainActor
final class JoinEventViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTicket: Ticket?
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var canJoinDirectly: Bool {
        // Public events: anyone can join
        if event.visibility == .openToAll {
            return true
        }
        
        // For requiresApproval or directInvites: can join if invited
        // Note: Invite checking not yet implemented, but structure supports it
        if event.visibility == .requiresApproval || event.visibility == .directInvites {
            // TODO: Check if user is invited when invites are implemented
            // For now, return false for these cases (will show request button)
            return false
        }
        
        return false
    }
    
    var canRequestToJoin: Bool {
        // Can request if requiresApproval and not invited
        if event.visibility == .requiresApproval {
            // TODO: Check if user is invited when invites are implemented
            // For now, assume not invited
            return true
        }
        return false
    }
    
    var requiresTicketSelection: Bool {
        !availableTickets.isEmpty
    }
    
    var shouldShowSheet: Bool {
        // Show sheet if there are tickets (even if all free, per user requirement)
        return !availableTickets.isEmpty
    }
    
    var availableTickets: [Ticket] {
        // Force materialization of tickets relationship if it's a fault
        guard let tickets = event.tickets else { return [] }
        
        // Access the count to force fault resolution
        let _ = tickets.count
        
        // Materialize each ticket to ensure they're fully loaded
        let materializedTickets = Array(tickets)
        for ticket in materializedTickets {
            let _ = ticket.id
            let _ = ticket.name
            let _ = ticket.priceCents
        }
        
        return materializedTickets.sorted { $0.name < $1.name }
    }
    
    var isSoldOut: Bool {
        event.maxCapacity > 0 && event.remainingCapacity <= 0
    }
    
    var hasSingleTicket: Bool {
        availableTickets.count == 1
    }
    
    var hasMultipleTickets: Bool {
        availableTickets.count > 1
    }
    
    var selectedTicketIsPaid: Bool {
        selectedTicket?.priceCents ?? 0 > 0
    }
    
    // MARK: - Button State Helpers
    
    /// Returns true if the join button should be disabled (sold out)
    var isButtonDisabled: Bool {
        isSoldOut
    }
    
    /// Returns the button title based on event state
    var buttonTitle: String {
        if isSoldOut {
            return "Sold Out"
        } else if availableTickets.isEmpty {
            return "Join"
        } else if hasSingleTicket {
            let ticket = availableTickets.first!
            return ticket.priceCents > 0 ? "Purchase \(ticket.formattedPrice)" : "Join"
        } else {
            return "Select Ticket"
        }
    }
    
    /// Returns true if we should show JoinEventSheet (multiple tickets)
    var shouldShowTicketSheet: Bool {
        hasMultipleTickets
    }
    
    /// Returns true if event is free (no tickets or all tickets are free)
    var isFreeEvent: Bool {
        availableTickets.isEmpty || availableTickets.allSatisfy { $0.priceCents == 0 }
    }
    
    /// Returns the single ticket if there's only one
    var singleTicket: Ticket? {
        hasSingleTicket ? availableTickets.first : nil
    }
    
    // MARK: - Private Properties
    private let event: EventItem
    private let currentUserID: UUID?
    private let memberRepository: MemberRepository
    
    // MARK: - Initialization
    init(
        event: EventItem,
        currentUserID: UUID? = nil,
        memberRepository: MemberRepository = CoreMemberRepository()
    ) {
        self.event = event
        self.currentUserID = currentUserID
        self.memberRepository = memberRepository
    }
    
    // MARK: - Public Methods
    
    func selectTicket(_ ticket: Ticket) {
        selectedTicket = ticket
    }
    
    func requestToJoin() async throws {
        guard !isSoldOut else {
            throw JoinError.eventSoldOut
        }
        
        guard canRequestToJoin else {
            throw JoinError.cannotRequestToJoin
        }
        
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        // TODO: Implement invite creation for join request
        // For now, this is a stub
        print("Requesting to join event: \(event.id)")
        
        // Simulate network call
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func joinEvent() async throws {
        guard !isSoldOut else {
            throw JoinError.eventSoldOut
        }
        
        guard canJoinDirectly else {
            throw JoinError.cannotJoinDirectly
        }
        
        guard let userID = currentUserID else {
            throw JoinError.userNotAuthenticated
        }
        
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        // Check if user is already a member
        let isMember = try await memberRepository.isUserMember(of: event.id, userID: userID)
        if isMember {
            throw JoinError.alreadyMember
        }
        
        // Get user profile info (simplified - in real app would fetch from UserProfileRepository)
        // For now, use placeholder values
        let displayName = "User" // TODO: Get from user profile
        let username: String? = nil // TODO: Get from user profile
        let avatarURL: String? = nil // TODO: Get from user profile
        
        // Create member
        _ = try await memberRepository.createMember(
            for: event.id,
            userID: userID,
            role: .guest,
            displayName: displayName,
            username: username,
            avatarURL: avatarURL
        )
    }
    
    func processPurchase() async throws {
        guard let ticket = selectedTicket else {
            throw JoinError.noTicketSelected
        }
        
        guard ticket.priceCents > 0 else {
            // Free ticket - just join
            try await joinEvent()
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        // Process Apple Pay
        let success = await processApplePay(for: ticket)
        
        if success {
            // After successful payment, join the event
            try await joinEvent()
        } else {
            throw JoinError.paymentFailed
        }
    }
    
    /// Handle join button tap - determines action based on event state
    func handleJoinButtonTap() async throws {
        guard !isSoldOut else {
            throw JoinError.eventSoldOut
        }
        
        // Free event - join directly
        if isFreeEvent {
            try await joinEvent()
            return
        }
        
        // Single paid ticket - select it and trigger Apple Pay
        if let ticket = singleTicket, ticket.priceCents > 0 {
            selectedTicket = ticket
            try await processPurchase()
            return
        }
        
        // Multiple tickets - should show sheet (handled by view)
        // This shouldn't be called in that case
        throw JoinError.noTicketSelected
    }
    
    // MARK: - Private Methods
    
    private func processApplePay(for ticket: Ticket) async -> Bool {
        print("Processing Apple Pay for ticket: \(ticket.name)")
        print("Amount: \(ticket.formattedPrice)")
        print("Event: \(event.name)")
        
        // TODO: Implement full PassKit integration with PKPaymentAuthorizationController
        // 1. Create PKPaymentRequest
        // 2. Present PKPaymentAuthorizationController
        // 3. Handle payment authorization
        // 4. Process payment with backend
        // 5. Return success/failure
        
        // Simulate payment processing
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        print("Apple Pay stub: Payment successful (simulated)")
        return true
    }
}

// MARK: - Join Errors

enum JoinError: LocalizedError {
    case eventSoldOut
    case cannotRequestToJoin
    case cannotJoinDirectly
    case userNotAuthenticated
    case alreadyMember
    case noTicketSelected
    case paymentFailed
    
    var errorDescription: String? {
        switch self {
        case .eventSoldOut:
            return "This event is sold out."
        case .cannotRequestToJoin:
            return "You cannot request to join this event."
        case .cannotJoinDirectly:
            return "You cannot join this event directly."
        case .userNotAuthenticated:
            return "You must be logged in to join events."
        case .alreadyMember:
            return "You are already a member of this event."
        case .noTicketSelected:
            return "Please select a ticket."
        case .paymentFailed:
            return "Payment processing failed. Please try again."
        }
    }
}


