//
//  MediaRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

public protocol MediaRepository: Sendable {
    // Event Media.
    func getEventMedia(for eventID: UUID, limit: Int?) async throws -> [EventMedia]
    func createEventMedia(for eventID: UUID, url: String, mimeType: String?, position: Int16) async throws -> EventMedia
    func deleteEventMedia(_ mediaID: UUID) async throws
    
    // Profile Media.
    func getProfileMedia(for profileID: UUID, limit: Int?) async throws -> [ProfileMedia]
    func createProfileMedia(for profileID: UUID, url: String, mimeType: String?, position: Int16) async throws -> ProfileMedia
    func deleteProfileMedia(_ mediaID: UUID) async throws
    
    // User Media.
    func getUserMedia(for profileID: UUID, limit: Int?) async throws -> [UserMedia]
    func createUserMedia(for profileID: UUID, url: String, mimeType: String?, position: Int16) async throws -> UserMedia
    func deleteUserMedia(_ mediaID: UUID) async throws
    
    // General Media Operations.
    func reorderEventMedia(_ mediaIDs: [UUID], for eventID: UUID) async throws
    func reorderUserMedia(_ mediaIDs: [UUID], for profileID: UUID) async throws
    func reorderProfileMedia(_ mediaIDs: [UUID], for profileID: UUID) async throws
    func updateMediaPosition(_ mediaID: UUID, position: Int16) async throws -> EventMedia?
    func cleanupOldMedia(olderThan date: Date) async throws -> Int
}

final class CoreDataMediaRepository: MediaRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - EVENT MEDIA:

    func getEventMedia(for eventID: UUID, limit: Int? = nil) async throws -> [EventMedia] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<EventMedia> = EventMedia.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@", eventID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventMedia.position, ascending: true)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let media = try context.fetch(request)
            return media
        }
    }
    
    func createEventMedia(for eventID: UUID, url: String, mimeType: String? = nil, position: Int16) async throws -> EventMedia {
        return try await coreDataStack.performBackgroundTask { context in
            // First fetch the event
            let eventRequest: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let event = try context.fetch(eventRequest).first else {
                throw RepositoryError.eventNotFound
            }
            
            let media = EventMedia(context: context)
            media.id = UUID()
            media.url = url
            media.mimeType = mimeType
            media.position = position
            media.event = event
            media.createdAt = Date()
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return media
        }
    }
    
    func deleteEventMedia(_ mediaID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<EventMedia> = EventMedia.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            if let media = try context.fetch(request).first {
                context.delete(media)
                try context.save()
            }
        }
    }
    
    // MARK: - PROFILE MEDIA:

    func getProfileMedia(for profileID: UUID, limit: Int? = nil) async throws -> [ProfileMedia] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<ProfileMedia> = ProfileMedia.fetchRequest()
            request.predicate = NSPredicate(format: "profile.id == %@", profileID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ProfileMedia.position, ascending: true)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let media = try context.fetch(request)
            return media
        }
    }
    
    func createProfileMedia(for profileID: UUID, url: String, mimeType: String? = nil, position: Int16) async throws -> ProfileMedia {
        return try await coreDataStack.performBackgroundTask { context in
            // First fetch the profile.
            let profileRequest: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", profileID as CVarArg)
            profileRequest.fetchLimit = 1
            
            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }
            
            let media = ProfileMedia(context: context)
            media.id = UUID()
            media.url = url
            media.mimeType = mimeType
            media.position = position
            media.profile = profile
            media.createdAt = Date()
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return media
        }
    }
    
    func deleteProfileMedia(_ mediaID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<ProfileMedia> = ProfileMedia.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            if let media = try context.fetch(request).first {
                context.delete(media)
                try context.save()
            }
        }
    }
    
    // MARK: - USER MEDIA:

    func getUserMedia(for profileID: UUID, limit: Int? = nil) async throws -> [UserMedia] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserMedia> = UserMedia.fetchRequest()
            request.predicate = NSPredicate(format: "ownerProfile.id == %@", profileID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserMedia.position, ascending: true)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let media = try context.fetch(request)
            return media
        }
    }
    
    func createUserMedia(for profileID: UUID, url: String, mimeType: String? = nil, position: Int16) async throws -> UserMedia {
        return try await coreDataStack.performBackgroundTask { context in
            // First fetch the profile.
            let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", profileID as CVarArg)
            profileRequest.fetchLimit = 1
            
            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }
            
            let media = UserMedia(context: context)
            media.id = UUID()
            media.url = url
            media.mimeType = mimeType
            media.position = position
            media.ownerProfile = profile
            media.createdAt = Date()
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return media
        }
    }
    
    func deleteUserMedia(_ mediaID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserMedia> = UserMedia.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            if let media = try context.fetch(request).first {
                context.delete(media)
                try context.save()
            }
        }
    }
    
    // MARK: - GENERAL MEDIA OPERATIONS:

    func reorderEventMedia(_ mediaIDs: [UUID], for eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (index, mediaID) in mediaIDs.enumerated() {
                let request: NSFetchRequest<EventMedia> = EventMedia.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
                request.fetchLimit = 1
                
                if let media = try context.fetch(request).first {
                    media.position = Int16(index)
                }
            }
            try context.save()
        }
    }
    
    func reorderUserMedia(_ mediaIDs: [UUID], for profileID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (index, mediaID) in mediaIDs.enumerated() {
                let request: NSFetchRequest<UserMedia> = UserMedia.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
                request.fetchLimit = 1
                
                if let media = try context.fetch(request).first {
                    media.position = Int16(index)
                }
            }
            try context.save()
        }
    }
    
    func reorderProfileMedia(_ mediaIDs: [UUID], for profileID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (index, mediaID) in mediaIDs.enumerated() {
                let request: NSFetchRequest<ProfileMedia> = ProfileMedia.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
                request.fetchLimit = 1
                
                if let media = try context.fetch(request).first {
                    media.position = Int16(index)
                }
            }
            try context.save()
        }
    }
    
    func updateMediaPosition(_ mediaID: UUID, position: Int16) async throws -> EventMedia? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<EventMedia> = EventMedia.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            guard let media = try context.fetch(request).first else { 
                throw RepositoryError.eventNotFound
            }
            
            media.position = position
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return media
        }
    }
    
    func cleanupOldMedia(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            var totalDeleted = 0
            
            // Clean up EventMedia.
            let eventMediaRequest: NSFetchRequest<EventMedia> = EventMedia.fetchRequest()
            eventMediaRequest.predicate = NSPredicate(format: "updatedAt < %@", date as NSDate)
            let oldEventMedia = try context.fetch(eventMediaRequest)
            for media in oldEventMedia {
                context.delete(media)
                totalDeleted += 1
            }
            
            // Clean up ProfileMedia.
            let profileMediaRequest: NSFetchRequest<ProfileMedia> = ProfileMedia.fetchRequest()
            profileMediaRequest.predicate = NSPredicate(format: "updatedAt < %@", date as NSDate)
            let oldProfileMedia = try context.fetch(profileMediaRequest)
            for media in oldProfileMedia {
                context.delete(media)
                totalDeleted += 1
            }
            
            // Clean up UserMedia.
            let userMediaRequest: NSFetchRequest<UserMedia> = UserMedia.fetchRequest()
            userMediaRequest.predicate = NSPredicate(format: "updatedAt < %@", date as NSDate)
            let oldUserMedia = try context.fetch(userMediaRequest)
            for media in oldUserMedia {
                context.delete(media)
                totalDeleted += 1
            }
            
            try context.save()
            return totalDeleted
        }
    }
}
