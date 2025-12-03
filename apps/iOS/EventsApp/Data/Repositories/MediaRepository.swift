//
//  MediaRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData

public protocol MediaRepository: Sendable {
    // Get media by owner.
    func getMedia(eventID: UUID, limit: Int?) async throws -> [Media]
    func getMedia(userProfileID: UUID, limit: Int?) async throws -> [Media]
    func getMedia(publicProfileID: UUID, limit: Int?) async throws -> [Media]
    
    // Create media for owner.
    func createMedia(eventID: UUID, url: String, mimeType: String?, position: Int16, averageColorHex: String?, primaryColorHex: String?, secondaryColorHex: String?) async throws -> Media
    func createMedia(userProfileID: UUID, url: String, mimeType: String?, position: Int16, averageColorHex: String?, primaryColorHex: String?, secondaryColorHex: String?) async throws -> Media
    func createMedia(publicProfileID: UUID, url: String, mimeType: String?, position: Int16, averageColorHex: String?, primaryColorHex: String?, secondaryColorHex: String?) async throws -> Media
    
    // Delete media.
    func deleteMedia(_ mediaID: UUID) async throws
    
    // Reorder media.
    func reorderMedia(_ mediaIDs: [UUID], eventID: UUID) async throws
    func reorderMedia(_ mediaIDs: [UUID], userProfileID: UUID) async throws
    func reorderMedia(_ mediaIDs: [UUID], publicProfileID: UUID) async throws
    
    // Update media position.
    func updateMediaPosition(_ mediaID: UUID, position: Int16) async throws -> Media?
    
    // Update media URL.
    func updateMediaURL(_ mediaID: UUID, url: String) async throws
    
    // Cleanup.
    func cleanupOldMedia(olderThan date: Date) async throws -> Int
}

public final class CoreMediaRepository: MediaRepository {
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - GET MEDIA:
    public func getMedia(eventID: UUID, limit: Int? = nil) async throws -> [Media] {
        // Fetch from view context to ensure we get properly loaded objects.
        return try await coreDataStack.viewContext.perform {
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "event.id == %@", eventID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Media.position, ascending: true)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let media = try self.coreDataStack.viewContext.fetch(request)
            // Force materialization.
            for m in media {
                let _ = m.id
                let _ = m.url
                let _ = m.position
                let _ = m.mimeType
            }
            return media
        }
    }
    
    public func getMedia(userProfileID: UUID, limit: Int? = nil) async throws -> [Media] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "userProfile.id == %@", userProfileID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Media.position, ascending: true)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let media = try context.fetch(request)
            return media
        }
    }
    
    public func getMedia(publicProfileID: UUID, limit: Int? = nil) async throws -> [Media] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "publicProfile.id == %@", publicProfileID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Media.position, ascending: true)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let media = try context.fetch(request)
            return media
        }
    }
    
    // MARK: - CREATE MEDIA:
    public func createMedia(eventID: UUID, url: String, mimeType: String? = nil, position: Int16, averageColorHex: String? = nil, primaryColorHex: String? = nil, secondaryColorHex: String? = nil) async throws -> Media {
        // First create the media ID so we can use it outside the background context.
        let mediaID = UUID()
        
        // Create and save the media in background context.
        try await coreDataStack.performBackgroundTask { context in
            // First, fetch the event.
            let eventRequest: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let event = try context.fetch(eventRequest).first else {
                throw RepositoryError.eventNotFound
            }
            
            let media = Media(context: context)
            media.id = mediaID
            media.url = url
            media.mimeType = mimeType
            media.position = position
            media.averageColorHex = averageColorHex
            media.primaryColorHex = primaryColorHex
            media.secondaryColorHex = secondaryColorHex
            media.event = event
            media.userProfile = nil
            media.publicProfile = nil
            media.createdAt = Date()
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            media.schemaVersion = 1
            
            try media.validateRelationships()
            
            // Explicitly ensure the inverse relationship is set on the event.
            // Core Data should do this automatically, but we will make sure.
            if event.media == nil {
                event.media = Set<Media>()
            }
            // The inverse relationship should already be set, but log for debugging
            print("MediaRepository | Created media \(mediaID) and assigned to event \(eventID).")

            try context.save()
            print("MediaRepository | Saved media \(mediaID) in background context.")
        }
        
        // Wait a moment for merge notification to propagate.
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds.

        // Now fetch the media AND refresh the event from the main context.
        return try await self.coreDataStack.viewContext.perform {
            // Fetch media.
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            guard let media = try self.coreDataStack.viewContext.fetch(request).first else {
                throw RepositoryError.mediaNotFound
            }
            
            // IMPORTANT: Also refresh the event to ensure it sees the new media relationship.
            let eventRequest: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            eventRequest.relationshipKeyPathsForPrefetching = ["media"]
            
            if let event = try? self.coreDataStack.viewContext.fetch(eventRequest).first {
                // Refresh the event to pick up the new media relationship.
                self.coreDataStack.viewContext.refresh(event, mergeChanges: true)
                // Force materialization of media relationship.
                if let mediaSet = event.media {
                    let _ = mediaSet.count
                    print("MediaRepository | Event \(eventID) now has \(mediaSet.count) media items in view context.")
                } else {
                    print("MediaRepository | Event \(eventID) has no media relationship (nil).")
                }
            }
            
            return media
        }
    }
    
    public func createMedia(userProfileID: UUID, url: String, mimeType: String? = nil, position: Int16, averageColorHex: String? = nil, primaryColorHex: String? = nil, secondaryColorHex: String? = nil) async throws -> Media {
        // First create the media ID so we can use it outside the background context.
        let mediaID = UUID()
        
        // Create and save the media in background context.
        try await coreDataStack.performBackgroundTask { context in
            // First, fetch the profile.
            let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", userProfileID as CVarArg)
            profileRequest.fetchLimit = 1
            
            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }
            
            let media = Media(context: context)
            media.id = mediaID
            media.url = url
            media.mimeType = mimeType
            media.position = position
            media.averageColorHex = averageColorHex
            media.primaryColorHex = primaryColorHex
            media.secondaryColorHex = secondaryColorHex
            media.userProfile = profile
            media.event = nil
            media.publicProfile = nil
            media.createdAt = Date()
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            media.schemaVersion = 1
            
            try media.validateRelationships()
            
            // Explicitly ensure the inverse relationship is set on the profile.
            // Core Data should do this automatically, but we will make sure.
            if profile.media == nil {
                profile.media = Set<Media>()
            }
            // The inverse relationship should already be set, but log for debugging
            print("MediaRepository | Created media \(mediaID) and assigned to userProfile \(userProfileID).")
            
            try context.save()
            print("MediaRepository | Saved media \(mediaID) in background context.")
        }
        
        // Wait a moment for merge notification to propagate.
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        
        // Now fetch the media from the main context to return a safe object.
        return try await self.coreDataStack.viewContext.perform {
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            guard let media = try self.coreDataStack.viewContext.fetch(request).first else {
                throw RepositoryError.mediaNotFound
            }
            
            return media
        }
    }
    
    public func createMedia(publicProfileID: UUID, url: String, mimeType: String? = nil, position: Int16, averageColorHex: String? = nil, primaryColorHex: String? = nil, secondaryColorHex: String? = nil) async throws -> Media {
        return try await coreDataStack.performBackgroundTask { context in
            // First, fetch the profile.
            let profileRequest: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", publicProfileID as CVarArg)
            profileRequest.fetchLimit = 1
            
            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }
            
            let media = Media(context: context)
            media.id = UUID()
            media.url = url
            media.mimeType = mimeType
            media.position = position
            media.averageColorHex = averageColorHex
            media.primaryColorHex = primaryColorHex
            media.secondaryColorHex = secondaryColorHex
            media.publicProfile = profile
            media.event = nil
            media.userProfile = nil
            media.createdAt = Date()
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            media.schemaVersion = 1
            
            try media.validateRelationships()
            try context.save()
            return media
        }
    }
    
    // MARK: - DELETE MEDIA:
    public func deleteMedia(_ mediaID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            if let media = try context.fetch(request).first {
                // Delete associated local file if it exists.
                let urlString = media.url
                if !urlString.isEmpty {
                    if urlString.hasPrefix("file://") || (!urlString.hasPrefix("http://") && !urlString.hasPrefix("https://")) {
                        // It is a local file URL.
                        let fileURL: URL
                        if urlString.hasPrefix("file://") {
                            if let url = URL(string: urlString) {
                                fileURL = url
                            } else {
                                let path = String(urlString.dropFirst(7))
                                fileURL = URL(fileURLWithPath: path)
                            }
                        } else {
                            fileURL = URL(fileURLWithPath: urlString)
                        }
                        
                        // Delete the local file.
                        try? MediaStorageHelper.deleteMediaFile(at: fileURL)
                    }
                }
                
                context.delete(media)
                try context.save()
            }
        }
    }
    
    // MARK: - REORDER MEDIA:
    public func reorderMedia(_ mediaIDs: [UUID], eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (index, mediaID) in mediaIDs.enumerated() {
                let request: NSFetchRequest<Media> = Media.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@ AND event.id == %@", mediaID as CVarArg, eventID as CVarArg)
                request.fetchLimit = 1
                
                if let media = try context.fetch(request).first {
                    media.position = Int16(index)
                }
            }
            try context.save()
        }
    }
    
    public func reorderMedia(_ mediaIDs: [UUID], userProfileID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (index, mediaID) in mediaIDs.enumerated() {
                let request: NSFetchRequest<Media> = Media.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@ AND userProfile.id == %@", mediaID as CVarArg, userProfileID as CVarArg)
                request.fetchLimit = 1
                
                if let media = try context.fetch(request).first {
                    media.position = Int16(index)
                }
            }
            try context.save()
        }
    }
    
    public func reorderMedia(_ mediaIDs: [UUID], publicProfileID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (index, mediaID) in mediaIDs.enumerated() {
                let request: NSFetchRequest<Media> = Media.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@ AND publicProfile.id == %@", mediaID as CVarArg, publicProfileID as CVarArg)
                request.fetchLimit = 1
                
                if let media = try context.fetch(request).first {
                    media.position = Int16(index)
                }
            }
            try context.save()
        }
    }
    
    // MARK: - UPDATE MEDIA POSITION:
    public func updateMediaPosition(_ mediaID: UUID, position: Int16) async throws -> Media? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            guard let media = try context.fetch(request).first else {
                throw RepositoryError.mediaNotFound
            }
            
            media.position = position
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return media
        }
    }
    
    // MARK: - UPDATE MEDIA URL:
    public func updateMediaURL(_ mediaID: UUID, url: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            
            guard let media = try context.fetch(request).first else {
                throw RepositoryError.mediaNotFound
            }
            
            print("MediaRepository | Updating media \(mediaID) URL from \(media.url) to \(url).")
            media.url = url
            media.updatedAt = Date()
            media.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            print("MediaRepository | Media URL updated successfully!")
        }
        
        // Refresh the specific media object and its event relationship in view context.
        await MainActor.run {
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            request.fetchLimit = 1
            request.relationshipKeyPathsForPrefetching = ["event"]
            
            if let media = try? coreDataStack.viewContext.fetch(request).first {
                coreDataStack.viewContext.refresh(media, mergeChanges: true)
                
                // Also refresh the event to ensure media relationship is updated
                if let event = media.event {
                    coreDataStack.viewContext.refresh(event, mergeChanges: true)
                    print("MediaRepository | Refreshed media and event objects in view context.")
                } else {
                    print("MediaRepository | Refreshed media object in view context (no event relationship).")
                }
            }
        }
    }
    
    // MARK: - CLEANUP:
    public func cleanupOldMedia(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Media> = Media.fetchRequest()
            request.predicate = NSPredicate(format: "updatedAt < %@", date as NSDate)
            
            let oldMedia = try context.fetch(request)
            for media in oldMedia {
                context.delete(media)
            }
            
            try context.save()
            return oldMedia.count
        }
    }
}
