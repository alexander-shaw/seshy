//
//  OwnedMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/9/25.
//

// MARK: Inherits MediaBase.

import Foundation
import CoreData

@objc(OwnedMedia)
public class OwnedMedia: MediaBase {}

public extension OwnedMedia {
    @nonobjc class func fetchRequest() -> NSFetchRequest<OwnedMedia> {
        NSFetchRequest<OwnedMedia>(entityName: "OwnedMedia")
    }

    @NSManaged var uploadedAt: Date
    @NSManaged var ownerProfile: UserProfile?  // Inverse: UserProfile.media (Cascade).
    @NSManaged var event: PartyEvent?  // Inverse: PartyEvent.media (Nullify or Cascade).

    // Local & Cloud Storage:
    @NSManaged var lastLocallySavedAt: Date?
    @NSManaged var lastCloudSyncedAt: Date?
    @NSManaged var syncStatusRaw: Int16

}

extension OwnedMedia {
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
