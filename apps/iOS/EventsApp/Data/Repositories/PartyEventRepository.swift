//
//  UserEventRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import UIKit
import CoreDomain

public protocol UserEventRepository: Sendable {
    func createEvent(name: String, details: String?, brandColor: String, startTime: Date?, endTime: Date?, durationMinutes: Int64?, isAllDay: Bool, location: Place?, maxCapacity: Int64, visibility: UserEventVisibility, inviteLink: String?, status: UserEventStatus) async throws -> UserEvent
    func getEvent(by id: UUID) async throws -> UserEvent?
    func getAllEvents() async throws -> [UserEvent]
    func getPublishedEvents() async throws -> [UserEvent]
    func getDraftEvents() async throws -> [UserEvent]
    func getUpcomingEvents() async throws -> [UserEvent]
    func getLiveEvents() async throws -> [UserEvent]
    func getPastEvents() async throws -> [UserEvent]
    func getEvents(for userID: UUID) async throws -> [UserEvent]
    func updateEvent(_ event: UserEvent) async throws -> UserEvent?
    func deleteEvent(_ eventID: UUID) async throws
    func updateEventStatus(_ eventID: UUID, status: UserEventStatus) async throws -> UserEvent?
    func getEventsByVisibility(_ visibility: UserEventVisibility) async throws -> [UserEvent]
    func searchEvents(query: String) async throws -> [UserEvent]
    func getEventsWithTags(_ tagIDs: [UUID]) async throws -> [UserEvent]
}

final class CoreDataUserEventRepository: UserEventRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createEvent(name: String, details: String? = nil, brandColor: String = "#007AFF", startTime: Date? = nil, endTime: Date? = nil, durationMinutes: Int64? = nil, isAllDay: Bool = false, location: Place?, maxCapacity: Int64, visibility: UserEventVisibility, inviteLink: String? = nil, status: UserEventStatus = .draft) async throws -> UserEvent {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    // Create the event in the main context.
                    let event = UserEvent(context: self.coreDataStack.viewContext)
                    event.id = UUID()
                    event.createdAt = Date()
                    event.updatedAt = Date()
                    event.name = name
                    event.details = details
                    event.brandColor = brandColor
                    event.startTime = startTime
                    event.endTime = endTime
                    event.durationMinutes = durationMinutes.map { NSNumber(value: $0) }
                    event.isAllDay = isAllDay
                    // The location was created in the same viewContext, so we can assign directly.
                    event.location = location
                    event.maxCapacity = maxCapacity
                    event.visibilityRaw = visibility.rawValue
                    event.inviteLink = inviteLink
                    event.scheduleStatusRaw = status.rawValue
                    event.syncStatusRaw = SyncStatus.pending.rawValue
                    event.schemaVersion = 1
                    
                    try self.coreDataStack.viewContext.save()
                    continuation.resume(returning: event)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getEvent(by id: UUID) async throws -> UserEvent? {
        // Fetch from view context to ensure we get a main-thread-safe object
        return try await coreDataStack.viewContext.perform {
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            // Prefetch media relationship to ensure it's loaded
            request.relationshipKeyPathsForPrefetching = ["media"]
            
            let event = try self.coreDataStack.viewContext.fetch(request).first
            
            // Force materialization of media relationship
            if let event = event, let mediaSet = event.media {
                let _ = mediaSet.count
                for media in mediaSet {
                    let _ = media.id
                    let _ = media.url
                }
                print("✅ [PartyEventRepository] getEvent: Event '\(event.name)' has \(mediaSet.count) media items")
            } else if let event = event {
                print("⚠️ [PartyEventRepository] getEvent: Event '\(event.name)' has no media (nil)")
            }
            
            return event
        }
    }
    
    func getAllEvents() async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func getPublishedEvents() async throws -> [UserEvent] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
                    // Only fetch published events (not drafts) and events with a location
                    request.predicate = NSPredicate(format: "scheduleStatusRaw != %d AND location != nil", UserEventStatus.draft.rawValue)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
                    
                    // Prefetch relationships to avoid faults
                    request.relationshipKeyPathsForPrefetching = ["location", "media"]
                    
                    let events = try self.coreDataStack.viewContext.fetch(request)
                    
                    // Force fault resolution for location and media objects to ensure they're fully loaded
                    for event in events {
                        if let place = event.location {
                            let _ = place.objectID
                            let _ = place.latitude
                            let _ = place.longitude
                            let _ = place.name
                        }
                        if let mediaSet = event.media {
                            let _ = mediaSet.count
                            // Access each media item to force fault resolution
                            for media in mediaSet {
                                let _ = media.id
                                let _ = media.url
                                let _ = media.position
                                let _ = media.mimeType
                            }
                            print("📦 [PartyEventRepository] Prefetched \(mediaSet.count) media items for event '\(event.name)'")
                        }
                    }
                    
                    print("📊 Fetched \(events.count) published events with locations")
                    continuation.resume(returning: events)
                } catch {
                    print("❌ Error fetching published events: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getDraftEvents() async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "scheduleStatusRaw == %d", UserEventStatus.draft.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.updatedAt, ascending: false)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func getUpcomingEvents() async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "startTime > %@ AND scheduleStatusRaw != %d", 
                                          Date() as NSDate, UserEventStatus.cancelled.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func getLiveEvents() async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let now = Date()
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "startTime <= %@ AND (endTime == nil OR endTime >= %@) AND scheduleStatusRaw != %d", 
                                          now as NSDate, now as NSDate, UserEventStatus.cancelled.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func getPastEvents() async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "(endTime != nil AND endTime < %@) OR scheduleStatusRaw == %d OR scheduleStatusRaw == %d", 
                                          Date() as NSDate, UserEventStatus.ended.rawValue, UserEventStatus.cancelled.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: false)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func getEvents(for userID: UUID) async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "ANY members.userID == %@", userID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func updateEvent(_ event: UserEvent) async throws -> UserEvent? {
        return try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return event
        }
    }
    
    func deleteEvent(_ eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            request.fetchLimit = 1
            
            if let event = try context.fetch(request).first {
                context.delete(event)
                try context.save()
            }
        }
    }
    
    func updateEventStatus(_ eventID: UUID, status: UserEventStatus) async throws -> UserEvent? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            request.fetchLimit = 1
            
            guard let event = try context.fetch(request).first else { return nil }
            
            event.scheduleStatusRaw = status.rawValue
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return event
        }
    }
    
    func getEventsByVisibility(_ visibility: UserEventVisibility) async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "visibilityRaw == %d", visibility.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func searchEvents(query: String) async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR details CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
    
    func getEventsWithTags(_ tagIDs: [UUID]) async throws -> [UserEvent] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            request.predicate = NSPredicate(format: "ANY tags.id IN %@", tagIDs)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEvent.startTime, ascending: true)]
            
            let events = try context.fetch(request)
            return events
        }
    }
}
