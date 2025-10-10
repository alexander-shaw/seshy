//
//  Invite.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

// MARK: Tracks the invitation flow with a simple status.
// Hosts invites user or user requests to join.  When approved, create Member.
// Points to PartyEvent.  Stores userID and lightweight snapshot.

import Foundation
import CoreData

@objc(Invite)
public class Invite: NSManagedObject {}

extension Invite {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invite> {
        NSFetchRequest<Invite>(entityName: "Invite")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?

    @NSManaged public var userID: UUID
    @NSManaged public var typeRaw: Int16  // InviteType.
    @NSManaged public var statusRaw: Int16  // InviteStatus.
    @NSManaged public var token: String?  // For link-based invites.
    @NSManaged public var expiresAt: Date?

    // Relationships:
    @NSManaged public var event: PartyEvent
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
