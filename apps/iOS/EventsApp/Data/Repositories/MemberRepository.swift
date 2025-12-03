//
//  MemberRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData

public protocol MemberRepository: Sendable {
    func createMember(for eventID: UUID, userID: UUID, role: MemberRole, displayName: String, username: String?, avatarURL: String?) async throws -> Member
    func getMember(by id: UUID) async throws -> Member?
    func getMembers(for eventID: UUID) async throws -> [Member]
    func getMember(for eventID: UUID, userID: UUID) async throws -> Member?
    func updateMemberRole(_ memberID: UUID, role: MemberRole) async throws -> Member?
    func updateMemberInfo(_ memberID: UUID, displayName: String?, username: String?, avatarURL: String?) async throws -> Member?
    func deleteMember(_ memberID: UUID) async throws
    func getHosts(for eventID: UUID) async throws -> [Member]
    func getGuests(for eventID: UUID) async throws -> [Member]
    func isUserMember(of eventID: UUID, userID: UUID) async throws -> Bool
    func canUserModifyEvent(userID: UUID, eventID: UUID) async throws -> Bool
}

final class CoreMemberRepository: MemberRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createMember(for eventID: UUID, userID: UUID, role: MemberRole, displayName: String, username: String? = nil, avatarURL: String? = nil) async throws -> Member {
        return try await coreDataStack.performBackgroundTask { context in
            // First, fetch the event.
            let eventRequest: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let event = try context.fetch(eventRequest).first else {
                throw RepositoryError.eventNotFound
            }
            
            let member = Member(context: context)
            member.id = UUID()
            member.createdAt = Date()
            member.updatedAt = Date()
            member.userID = userID
            member.roleRaw = role.rawValue
            member.displayName = displayName
            member.username = username
            member.avatarURL = avatarURL
            member.event = event
            member.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return member
        }
    }
    
    func getMember(by id: UUID) async throws -> Member? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let members = try context.fetch(request)
            return members.first
        }
    }
    
    func getMembers(for eventID: UUID) async throws -> [Member] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@", eventID as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Member.roleRaw, ascending: true), // Hosts first
                NSSortDescriptor(keyPath: \Member.displayName, ascending: true)
            ]
            
            let members = try context.fetch(request)
            return members
        }
    }
    
    func getMember(for eventID: UUID, userID: UUID) async throws -> Member? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@ AND userID == %@", eventID as CVarArg, userID as CVarArg)
            request.fetchLimit = 1
            
            let members = try context.fetch(request)
            return members.first
        }
    }
    
    func updateMemberRole(_ memberID: UUID, role: MemberRole) async throws -> Member? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", memberID as CVarArg)
            request.fetchLimit = 1
            
            guard let member = try context.fetch(request).first else { return nil }
            
            member.roleRaw = role.rawValue
            member.updatedAt = Date()
            member.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return member
        }
    }
    
    func updateMemberInfo(_ memberID: UUID, displayName: String? = nil, username: String? = nil, avatarURL: String? = nil) async throws -> Member? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", memberID as CVarArg)
            request.fetchLimit = 1
            
            guard let member = try context.fetch(request).first else { return nil }
            
            if let displayName = displayName {
                member.displayName = displayName
            }
            if let username = username {
                member.username = username
            }
            if let avatarURL = avatarURL {
                member.avatarURL = avatarURL
            }
            
            member.updatedAt = Date()
            member.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return member
        }
    }
    
    func deleteMember(_ memberID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", memberID as CVarArg)
            request.fetchLimit = 1
            
            if let member = try context.fetch(request).first {
                context.delete(member)
                try context.save()
            }
        }
    }
    
    func getHosts(for eventID: UUID) async throws -> [Member] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@ AND roleRaw == %d", eventID as CVarArg, MemberRole.host.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Member.displayName, ascending: true)]
            
            let members = try context.fetch(request)
            return members
        }
    }
    
    func getGuests(for eventID: UUID) async throws -> [Member] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Member> = Member.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@ AND roleRaw == %d", eventID as CVarArg, MemberRole.guest.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Member.displayName, ascending: true)]
            
            let members = try context.fetch(request)
            return members
        }
    }
    
    func isUserMember(of eventID: UUID, userID: UUID) async throws -> Bool {
        let member = try await getMember(for: eventID, userID: userID)
        return member != nil
    }
    
    func canUserModifyEvent(userID: UUID, eventID: UUID) async throws -> Bool {
        guard let member = try await getMember(for: eventID, userID: userID) else { return false }
        return member.roleRaw == MemberRole.host.rawValue || member.roleRaw == MemberRole.staff.rawValue
    }
}
