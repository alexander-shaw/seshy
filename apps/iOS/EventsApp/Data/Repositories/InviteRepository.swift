//
//  InviteRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

public protocol InviteRepository: Sendable {
    func createInvite(for eventID: UUID, userID: UUID, type: InviteType, token: String?) async throws -> Invite
    func getInvite(by id: UUID) async throws -> Invite?
    func getInvites(for eventID: UUID) async throws -> [Invite]
    func getInvitesForUser(_ userID: UUID) async throws -> [Invite]
    func updateInviteStatus(_ inviteID: UUID, status: InviteStatus) async throws -> Invite?
    func deleteInvite(_ inviteID: UUID) async throws
    func getPendingInvites(for eventID: UUID) async throws -> [Invite]
    func getExpiredInvites() async throws -> [Invite]
    func cleanupExpiredInvites() async throws -> Int
}

final class CoreDataInviteRepository: InviteRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createInvite(for eventID: UUID, userID: UUID, type: InviteType, token: String? = nil) async throws -> Invite {
        return try await coreDataStack.performBackgroundTask { context in
            // First fetch the event.
            let eventRequest: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let event = try context.fetch(eventRequest).first else {
                throw RepositoryError.eventNotFound
            }
            
            let invite = Invite(context: context)
            invite.id = UUID()
            invite.createdAt = Date()
            invite.updatedAt = Date()
            invite.userID = userID
            invite.typeRaw = type.rawValue
            invite.statusRaw = InviteStatus.pending.rawValue
            invite.token = token
            invite.event = event
            invite.syncStatusRaw = SyncStatus.pending.rawValue
            
            // Set expiration to 7 days from now.
            invite.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
            
            try context.save()
            return invite
        }
    }
    
    func getInvite(by id: UUID) async throws -> Invite? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let invites = try context.fetch(request)
            return invites.first
        }
    }
    
    func getInvites(for eventID: UUID) async throws -> [Invite] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@", eventID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Invite.createdAt, ascending: false)]
            
            let invites = try context.fetch(request)
            return invites
        }
    }
    
    func getInvitesForUser(_ userID: UUID) async throws -> [Invite] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Invite.createdAt, ascending: false)]
            
            let invites = try context.fetch(request)
            return invites
        }
    }
    
    func updateInviteStatus(_ inviteID: UUID, status: InviteStatus) async throws -> Invite? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", inviteID as CVarArg)
            request.fetchLimit = 1
            
            guard let invite = try context.fetch(request).first else { return nil }
            
            invite.statusRaw = status.rawValue
            invite.updatedAt = Date()
            invite.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return invite
        }
    }
    
    func deleteInvite(_ inviteID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", inviteID as CVarArg)
            request.fetchLimit = 1
            
            if let invite = try context.fetch(request).first {
                context.delete(invite)
                try context.save()
            }
        }
    }
    
    func getPendingInvites(for eventID: UUID) async throws -> [Invite] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@ AND statusRaw == %d", eventID as CVarArg, InviteStatus.pending.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Invite.createdAt, ascending: false)]
            
            let invites = try context.fetch(request)
            return invites
        }
    }
    
    func getExpiredInvites() async throws -> [Invite] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "expiresAt < %@ AND statusRaw == %d", 
                                          Date() as NSDate, InviteStatus.pending.rawValue)
            
            let invites = try context.fetch(request)
            return invites
        }
    }
    
    func cleanupExpiredInvites() async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Invite> = Invite.fetchRequest()
            request.predicate = NSPredicate(format: "expiresAt < %@ AND statusRaw == %d", 
                                          Date() as NSDate, InviteStatus.pending.rawValue)
            
            let expiredInvites = try context.fetch(request)
            let count = expiredInvites.count
            
            for invite in expiredInvites {
                invite.statusRaw = InviteStatus.expired.rawValue
                invite.updatedAt = Date()
                invite.syncStatusRaw = SyncStatus.pending.rawValue
            }
            
            try context.save()
            return count
        }
    }
}
