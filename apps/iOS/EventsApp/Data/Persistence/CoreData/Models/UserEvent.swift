//
//  UserEvent.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// This file defines the Core Data entity for events.
// It includes event details, scheduling, location, members, and media.

import Foundation
import CoreData
import CoreDomain

@objc(UserEvent)
public class UserEvent: NSManagedObject {}

extension UserEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEvent> {
        NSFetchRequest<UserEvent>(entityName: "UserEvent")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var scheduleStatusRaw: Int16

    @NSManaged public var name: String
    @NSManaged public var details: String?
    @NSManaged public var brandColor: String

    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var durationMinutes: NSNumber?
    @NSManaged public var isAllDay: Bool
    @NSManaged public var location: Place?

    @NSManaged public var maxCapacity: Int64
    @NSManaged public var visibilityRaw: Int16
    @NSManaged public var inviteLink: String?

    // Relationships:
    @NSManaged public var media: Set<Media>?  // Durable, official gallery.
    @NSManaged public var previews: Set<Media>?  // Evictable cache thumbnails.
    @NSManaged public var tags: Set<Tag>?  // Highly encouraged.
    @NSManaged public var members: Set<Member>  // One or more.  Host, at minimum.
}

extension UserEvent {
    public var scheduleStatus: UserEventStatus {
        get { UserEventStatus(rawValue: scheduleStatusRaw) ?? .upcoming }
        set { scheduleStatusRaw = newValue.rawValue }
    }

    public var visibility: UserEventVisibility {
        get { UserEventVisibility(rawValue: visibilityRaw) ?? .requiresApproval }
        set { visibilityRaw = newValue.rawValue }
    }

    public var isUpcoming: Bool {
        guard scheduleStatus != .cancelled, scheduleStatus != .ended else { return false }
        guard let start = startTime else { return false }
        return Date() < start
    }

    public var isLiveNow: Bool {
        guard scheduleStatus != .cancelled else { return false }
        guard let start = startTime else { return false }
        let now = Date()
        if let end = endTime {
            return now >= start && now <= end
        } else {
            return now >= start
        }
    }

    public var isEnded: Bool {
        if scheduleStatus == .ended || scheduleStatus == .cancelled { return true }
        if let end = endTime { return Date() > end }
        return false
    }
}

extension UserEvent {
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
        return !isAtCapacity && scheduleStatus != .ended && scheduleStatus != .cancelled
    }
}

// Local & Cloud Storage:
extension UserEvent: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int16

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
