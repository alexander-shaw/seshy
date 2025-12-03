//
//  EventItemRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import UIKit

public protocol EventItemRepository: Sendable {
    func createEvent(name: String, details: String?, themePrimaryHex: String?, themeSecondaryHex: String?, themeMode: String?, startTime: Date?, endTime: Date?, durationMinutes: Int64?, isAllDay: Bool, location: Place?, maxCapacity: Int64, visibility: EventVisibility, inviteLink: String?, status: EventStatus) async throws -> EventItem
    func createEventWithRelationships(name: String, details: String?, themePrimaryHex: String?, themeSecondaryHex: String?, themeMode: String?, startTime: Date?, endTime: Date?, durationMinutes: Int64?, isAllDay: Bool, place: Place?, vibes: Set<Vibe>, tickets: Set<Ticket>?, maxCapacity: Int64, visibility: EventVisibility, inviteLink: String?, status: EventStatus, in context: NSManagedObjectContext) throws -> EventItem
    func getEvent(by id: UUID) async throws -> EventItem?
    func getAllEvents() async throws -> [EventItem]
    func getPublishedEvents() async throws -> [EventItem]
    func getDraftEvents() async throws -> [EventItem]
    func getUpcomingEvents() async throws -> [EventItem]
    func getLiveEvents() async throws -> [EventItem]
    func getPastEvents() async throws -> [EventItem]
    func getEvents(for userID: UUID) async throws -> [EventItem]
    func updateEvent(_ event: EventItem) async throws -> EventItem?
    func deleteEvent(_ eventID: UUID) async throws
    func updateEventStatus(_ eventID: UUID, status: EventStatus) async throws -> EventItem?
    func toggleBookmark(_ eventID: UUID) async throws -> EventItem?
    func getEventsByVisibility(_ visibility: EventVisibility) async throws -> [EventItem]
    func searchEvents(query: String) async throws -> [EventItem]
    func getEventsWithTags(_ tagIDs: [UUID]) async throws -> [EventItem]
}


public final class CoreEventItemRepository: EventItemRepository {
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    public func createEvent(name: String, details: String? = nil, themePrimaryHex: String? = nil, themeSecondaryHex: String? = nil, themeMode: String? = nil, startTime: Date? = nil, endTime: Date? = nil, durationMinutes: Int64? = nil, isAllDay: Bool = false, location: Place?, maxCapacity: Int64, visibility: EventVisibility, inviteLink: String? = nil, status: EventStatus = .draft) async throws -> EventItem {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    // Create the event in the main context.
                    let event = EventItem(context: self.coreDataStack.viewContext)
                    event.id = UUID()
                    event.createdAt = Date()
                    event.updatedAt = Date()
                    event.name = name
                    event.details = details
                    event.themePrimaryHex = themePrimaryHex
                    event.themeSecondaryHex = themeSecondaryHex
                    event.themeMode = themeMode
                    event.startTime = startTime
                    event.endTime = endTime
                    event.durationMinutes = durationMinutes.map { NSNumber(value: $0) }
                    event.isAllDay = isAllDay
                    // The location must come from CoreDataStack.shared.viewContext to avoid cross-context issues.
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
    
    /// Creates an event with all relationships (Place, Vibes, Tickets) in the same context.
    /// This method should be called from within a context.perform block.
    public func createEventWithRelationships(
        name: String,
        details: String? = nil,
        themePrimaryHex: String? = nil,
        themeSecondaryHex: String? = nil,
        themeMode: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        durationMinutes: Int64? = nil,
        isAllDay: Bool = false,
        place: Place?, // Existing Place in context (optional)
        vibes: Set<Vibe>, // Vibes already in context
        tickets: Set<Ticket>? = nil, // Tickets already in context (optional)
        maxCapacity: Int64,
        visibility: EventVisibility,
        inviteLink: String? = nil,
        status: EventStatus = .draft,
        in context: NSManagedObjectContext
    ) throws -> EventItem {
        
        // 1. Create the Event in the same context
        let event = EventItem(context: context)
        event.id = UUID()
        event.createdAt = Date()
        event.updatedAt = Date()
        event.name = name
        event.details = details
        event.themePrimaryHex = themePrimaryHex
        event.themeSecondaryHex = themeSecondaryHex
        event.themeMode = themeMode
        event.startTime = startTime
        event.endTime = endTime
        event.durationMinutes = durationMinutes.map { NSNumber(value: $0) }
        event.isAllDay = isAllDay
        event.location = place // Set relationship (optional - may be nil)
        event.maxCapacity = maxCapacity
        event.visibilityRaw = visibility.rawValue
        event.inviteLink = inviteLink
        event.scheduleStatusRaw = status.rawValue
        event.syncStatusRaw = SyncStatus.pending.rawValue
        event.schemaVersion = 1
        
        // 2. Set vibes relationship (many-to-many)
        if !vibes.isEmpty {
            event.vibes = vibes
        }
        
        // 3. Link tickets to event (if provided)
        if let ticketsToLink = tickets, !ticketsToLink.isEmpty {
            // Refetch tickets in this context to ensure they're in the same context
            let ticketIDs = ticketsToLink.map { $0.id }
            let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ticketIDs)
            let ticketsInContext = try context.fetch(request)
            event.tickets = Set(ticketsInContext)
        }
        
        // Note: Don't save here - caller should save the context after all operations
        
        return event
    }
    
    public func getEvent(by id: UUID) async throws -> EventItem? {
        // Fetch from view context to ensure we get a main-thread-safe object
        return try await coreDataStack.viewContext.perform {
            let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            // Prefetch relationships to ensure they're loaded
            request.relationshipKeyPathsForPrefetching = ["media", "tickets"]
            
            let event = try self.coreDataStack.viewContext.fetch(request).first
            
            // Force materialization of relationships
            if let event = event {
                if let mediaSet = event.media {
                    let _ = mediaSet.count
                    for media in mediaSet {
                        let _ = media.id
                        let _ = media.url
                    }
                    print("EventItemRepository | getEvent: Event \(event.name) has \(mediaSet.count) media items.")
                } else {
                    print("EventItemRepository | getEvent: Event \(event.name) has no media (nil).")
                }
                
                // Force materialization of tickets relationship
                if let ticketsSet = event.tickets {
                    let _ = ticketsSet.count
                    for ticket in ticketsSet {
                        let _ = ticket.id
                        let _ = ticket.name
                        let _ = ticket.priceCents
                    }
                    print("EventItemRepository | getEvent: Event \(event.name) has \(ticketsSet.count) tickets.")
                } else {
                    print("EventItemRepository | getEvent: Event \(event.name) has no tickets (nil).")
                }
            }
            
            return event
        }
    }
    
    public func getAllEvents() async throws -> [EventItem] {
        try await fetchEvents { request in
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
    
    public func getPublishedEvents() async throws -> [EventItem] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
                    // Only fetch published events (not drafts) and events with a location
                    request.predicate = NSPredicate(format: "scheduleStatusRaw != %d AND location != nil", EventStatus.draft.rawValue)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
                    
                    // Prefetch relationships to avoid faults
                    request.relationshipKeyPathsForPrefetching = ["location", "media", "tickets"]
                    
                    let events = try self.coreDataStack.viewContext.fetch(request)
                    
                    // Force fault resolution for location, media, and tickets objects to ensure they're fully loaded
                    for event in events {
                        if let place = event.location {
                            let _ = place.objectID
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
                            print("EventItemRepository | Prefetched \(mediaSet.count) media items for event '\(event.name)'")
                        }
                        // Force materialization of tickets relationship
                        if let ticketsSet = event.tickets {
                            let _ = ticketsSet.count
                            for ticket in ticketsSet {
                                let _ = ticket.id
                                let _ = ticket.name
                                let _ = ticket.priceCents
                            }
                            print("EventItemRepository | Prefetched \(ticketsSet.count) tickets for event '\(event.name)'")
                        }
                    }
                    
                    print("Fetched \(events.count) published events with locations.")
                    continuation.resume(returning: events)
                } catch {
                    print("Error fetching published events:  \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getDraftEvents() async throws -> [EventItem] {
        try await fetchEvents { request in
            request.predicate = NSPredicate(format: "scheduleStatusRaw == %d", EventStatus.draft.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.updatedAt, ascending: false)]
        }
    }
    
    public func getUpcomingEvents() async throws -> [EventItem] {
        let now = Date()
        return try await fetchEvents { request in
            request.predicate = NSPredicate(
                format: "startTime > %@ AND scheduleStatusRaw != %d",
                now as NSDate,
                EventStatus.cancelled.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
    
    public func getLiveEvents() async throws -> [EventItem] {
        let now = Date()
        return try await fetchEvents { request in
            request.predicate = NSPredicate(
                format: "startTime <= %@ AND (endTime == nil OR endTime >= %@) AND scheduleStatusRaw != %d",
                now as NSDate,
                now as NSDate,
                EventStatus.cancelled.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
    
    public func getPastEvents() async throws -> [EventItem] {
        let now = Date()
        return try await fetchEvents { request in
            request.predicate = NSPredicate(
                format: "(endTime != nil AND endTime < %@) OR scheduleStatusRaw == %d OR scheduleStatusRaw == %d",
                now as NSDate,
                EventStatus.ended.rawValue,
                EventStatus.cancelled.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: false)]
        }
    }
    
    public func getEvents(for userID: UUID) async throws -> [EventItem] {
        try await fetchEvents { request in
            request.predicate = NSPredicate(format: "ANY members.userID == %@", userID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
    
    public func updateEvent(_ event: EventItem) async throws -> EventItem? {
        guard let context = event.managedObjectContext else {
            return nil
        }
        
        return try await context.perform {
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            try context.save()
            return event
        }
    }
    
    public func deleteEvent(_ eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            request.fetchLimit = 1
            
            if let event = try context.fetch(request).first {
                context.delete(event)
                try context.save()
            }
        }
    }
    
    public func toggleBookmark(_ eventID: UUID) async throws -> EventItem? {
        return try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
                    request.fetchLimit = 1
                    
                    guard let event = try context.fetch(request).first else {
                        continuation.resume(throwing: RepositoryError.eventNotFound)
                        return
                    }
                    
                    // Toggle bookmark on the context's queue
                    event.isBookmarked.toggle()
                    event.updatedAt = Date()
                    event.syncStatusRaw = SyncStatus.pending.rawValue
                    
                    try context.save()
                    continuation.resume(returning: event)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func updateEventStatus(_ eventID: UUID, status: EventStatus) async throws -> EventItem? {
        try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
                    request.fetchLimit = 1
                    
                    guard let event = try context.fetch(request).first else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    event.scheduleStatusRaw = status.rawValue
                    event.updatedAt = Date()
                    event.syncStatusRaw = SyncStatus.pending.rawValue
                    
                    try context.save()
                    continuation.resume(returning: event)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getEventsByVisibility(_ visibility: EventVisibility) async throws -> [EventItem] {
        try await fetchEvents { request in
            request.predicate = NSPredicate(format: "visibilityRaw == %d", visibility.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
    
    public func searchEvents(query: String) async throws -> [EventItem] {
        try await fetchEvents { request in
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR details CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
    
    public func getEventsWithTags(_ tagIDs: [UUID]) async throws -> [EventItem] {
        try await fetchEvents { request in
            request.predicate = NSPredicate(format: "ANY tags.id IN %@", tagIDs)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \EventItem.startTime, ascending: true)]
        }
    }
}

private extension CoreEventItemRepository {
    func fetchEvents(
        configure: @escaping (NSFetchRequest<EventItem>) -> Void = { _ in }
    ) async throws -> [EventItem] {
        try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
                    configure(request)
                    let events = try context.fetch(request)
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
