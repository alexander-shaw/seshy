//
//  Member.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// MARK: Represents someone in the PartyEvent with a clear role for permissions.
// Belongs to a PartyEvent.  Stores person as userID and snapshot.
// Invite approval creates a Member.

import Foundation
import CoreData

@objc(Member)
public class Member: NSManagedObject {}

extension Member {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Member> {
        NSFetchRequest<Member>(entityName: "Member")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var roleRaw: Int16  // MemberRole.

    @NSManaged public var userID: UUID
    @NSManaged public var displayName: String
    @NSManaged public var username: String?
    @NSManaged public var avatarURL: String?

    // Relationships:
    @NSManaged public var event: PartyEvent
}

extension Member {
    public var role: MemberRole {
        get { MemberRole(rawValue: roleRaw) ?? .guest }
        set { roleRaw = newValue.rawValue }
    }
}
