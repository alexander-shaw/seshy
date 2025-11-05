//
//  Invite.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

// Tracks the invitation flow with a simple status.
// Hosts invites user or user requests to join.  When approved, create Member.
// Points to UserEvent.  Stores userID and lightweight snapshot.

import Foundation
import CoreData
import CoreDomain

@objc(Invite)
public class Invite: NSManagedObject {}

extension Invite {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invite> {
        NSFetchRequest<Invite>(entityName: "Invite")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var userID: UUID
    @NSManaged public var typeRaw: Int16  // InviteType.
    @NSManaged public var statusRaw: Int16  // InviteStatus.
    @NSManaged public var token: String?  // For link-based invites.
    @NSManaged public var expiresAt: Date?

    // Relationships:
    @NSManaged public var event: EventItem
}

extension Invite {
    public var type: InviteType {
        get { InviteType(rawValue: typeRaw) ?? .invite }
        set { typeRaw = newValue.rawValue }
    }
    
    public var status: InviteStatus {
        get { InviteStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}

// Local & Cloud Storage:
extension Invite: SyncTrackable {
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
