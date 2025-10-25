//
//  ProfileMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

// Public profile galleries for other users.

import CoreData

@objc(ProfileMedia)
public class ProfileMedia: MediaBase {}

extension ProfileMedia {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileMedia> {
        NSFetchRequest<ProfileMedia>(entityName: "ProfileMedia")
    }

    // The public profile this media belongs to.
    @NSManaged public var profile: PublicProfile
}
