//
//  PartyEvent.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// MARK: Core event model for what/where/when + lists/media.

import Foundation
import CoreData

@objc(PartyEvent)
public class PartyEvent: NSManagedObject {}

extension PartyEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PartyEvent> {
        NSFetchRequest<PartyEvent>(entityName: "PartyEvent")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var statusRaw: Int16
    @NSManaged public var createdAt: Date
    @NSManaged public var lastUpdatedAt: Date

    @NSManaged public var name: String
    @NSManaged public var details: String?

    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var location: Place

    @NSManaged public var maxCapacity: Int64
    @NSManaged public var visibilityRaw: Int16
    @NSManaged public var inviteLink: String?

    // Relationships:
    @NSManaged public var media: Set<OwnedMedia>?  // Durable, official gallery.
    @NSManaged var previewPhotos: Set<EventMediaCache>?  // Evictable cache thumbnails.
    @NSManaged public var tags: Set<Tag>?  // Highly encouraged.
    @NSManaged public var members: Set<Member>  // One or more.  Host, at minimum.

    // Local & Cloud Storage:
    @NSManaged public var lastLocallySavedAt: Date?
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
}

extension PartyEvent {
    public var status: PartyEventStatus {
        get { PartyEventStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }

    public var visibility: PartyEventVisibility {
        get { PartyEventVisibility(rawValue: visibilityRaw) ?? .requiresApproval }
        set { visibilityRaw = newValue.rawValue }
    }

    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }

    public var isUpcoming: Bool {
        guard status != .cancelled, status != .ended else { return false }
        return Date() < startTime
    }

    public var isLiveNow: Bool {
        guard status != .cancelled else { return false }
        let now = Date()
        if let end = endTime {
            return now >= startTime && now <= end
        } else {
            return now >= startTime
        }
    }

    public var isEnded: Bool {
        if status == .ended || status == .cancelled { return true }
        if let end = endTime { return Date() > end }
        return false
    }
}

extension PartyEvent {
    public var currentCapacity: Int {
        return members.count
    }

    public var isAtCapacity: Bool {
        return currentCapacity >= maxCapacity
    }

    public var remainingCapacity: Int {
        return max(0, Int(maxCapacity) - currentCapacity)
    }

    public var canAddMoreMembers: Bool {
        return !isAtCapacity && status != .ended && status != .cancelled
    }
}
