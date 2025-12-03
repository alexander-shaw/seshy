//
//  TicketViewModel.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
final class TicketViewModel: ObservableObject {
    @Published var userTickets: [Ticket] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let repository: TicketRepository
    
    init(repository: TicketRepository = CoreTicketRepository()) {
        self.repository = repository
    }
    
    func loadAllTickets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            userTickets = try await repository.getAllTickets()
        } catch {
            errorMessage = "Failed to load tickets: \(error.localizedDescription)"
            userTickets = []
        }
        
        isLoading = false
    }
    
    func createTicket(name: String, priceDollars: Double) async throws -> Ticket {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw TicketError.invalidName
        }
        guard priceDollars >= 0 else {
            throw TicketError.invalidPrice
        }
        
        let priceCents = Int64(priceDollars * 100)
        let ticket = try await repository.createTicket(name: trimmedName, priceCents: priceCents)
        
        // Reload tickets to include the new one
        await loadAllTickets()
        
        return ticket
    }
    
    func updateTicket(_ ticket: Ticket, name: String, priceDollars: Double) async throws -> Ticket {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw TicketError.invalidName
        }
        guard priceDollars >= 0 else {
            throw TicketError.invalidPrice
        }
        
        ticket.name = trimmedName
        ticket.priceCents = Int64(priceDollars * 100)
        
        let updatedTicket = try await repository.updateTicket(ticket)
        await loadAllTickets()
        
        return updatedTicket
    }
    
    func deleteTicket(_ ticket: Ticket) async {
        do {
            try await repository.deleteTicket(ticket)
            await loadAllTickets()
        } catch {
            errorMessage = "Failed to delete ticket: \(error.localizedDescription)"
        }
    }
    
    func selectTicket(_ ticket: Ticket, in selectedTickets: inout Set<Ticket>) {
        selectedTickets.insert(ticket)
    }
    
    func deselectTicket(_ ticket: Ticket, in selectedTickets: inout Set<Ticket>) {
        selectedTickets.remove(ticket)
    }
}

enum TicketError: LocalizedError {
    case invalidName
    case invalidPrice
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Ticket name cannot be empty"
        case .invalidPrice:
            return "Price must be greater than or equal to 0"
        }
    }
}
