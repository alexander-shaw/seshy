//
//  ProfileMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/9/25.
//

// MARK: Inherits MediaBase.

import Foundation
import CoreData

@objc(ProfileMedia)
public class ProfileMedia: MediaBase {}

public extension ProfileMedia {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ProfileMedia> {
        NSFetchRequest<ProfileMedia>(entityName: "ProfileMedia")
    }

    @NSManaged var profile: PublicProfile  // Inverse: PublicProfile.photos (Cascade).
}
