//
//  UserMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

// The local user owns this media.

import CoreData

@objc(UserMedia)
public class UserMedia: MediaBase {}

extension UserMedia {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMedia> {
        NSFetchRequest<UserMedia>(entityName: "UserMedia")
    }

    @NSManaged public var ownerProfile: UserProfile
}
