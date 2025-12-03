//
//  TicketRepository.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import Foundation
import CoreData

protocol TicketRepository {
    func createTicket(name: String, priceCents: Int64) async throws -> Ticket
    func getAllTickets() async throws -> [Ticket]
    func getTicket(by id: UUID) async throws -> Ticket?
    func updateTicket(_ ticket: Ticket) async throws -> Ticket
    func deleteTicket(_ ticket: Ticket) async throws
}

final class CoreTicketRepository: TicketRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createTicket(name: String, priceCents: Int64) async throws -> Ticket {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let ticket = Ticket(context: self.coreDataStack.viewContext)
                    ticket.id = UUID()
                    ticket.name = name
                    ticket.priceCents = priceCents
                    
                    // Set SyncTrackable attributes
                    let now = Date()
                    ticket.createdAt = now
                    ticket.updatedAt = now
                    ticket.deletedAt = nil
                    ticket.syncStatusRaw = SyncStatus.pending.rawValue
                    ticket.lastCloudSyncedAt = nil
                    ticket.schemaVersion = 1
                    
                    // Save immediately to get permanent objectID
                    try self.coreDataStack.viewContext.save()
                    continuation.resume(returning: ticket)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getAllTickets() async throws -> [Ticket] {
        try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.name, ascending: true)]
                    
                    let tickets = try context.fetch(request)
                    continuation.resume(returning: tickets)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getTicket(by id: UUID) async throws -> Ticket? {
        try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    
                    let ticket = try context.fetch(request).first
                    continuation.resume(returning: ticket)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateTicket(_ ticket: Ticket) async throws -> Ticket {
        let objectID = ticket.objectID
        let updatedName = ticket.name
        let updatedPrice = ticket.priceCents
        
        return try await coreDataStack.performBackgroundTask { context in
            guard let contextTicket = try context.existingObject(with: objectID) as? Ticket else {
                throw RepositoryError.eventNotFound
            }
            contextTicket.name = updatedName
            contextTicket.priceCents = updatedPrice
            contextTicket.updatedAt = Date()
            contextTicket.syncStatusRaw = SyncStatus.pending.rawValue
            try context.save()
            return contextTicket
        }
    }
    
    func deleteTicket(_ ticket: Ticket) async throws {
        let objectID = ticket.objectID
        
        return try await coreDataStack.performBackgroundTask { context in
            guard let contextTicket = try context.existingObject(with: objectID) as? Ticket else {
                throw RepositoryError.eventNotFound
            }
            context.delete(contextTicket)
            try context.save()
        }
    }
}


