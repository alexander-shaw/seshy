//
//  MediaBase.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

import CoreData
import CoreDomain

@objc(MediaBase)
public class MediaBase: NSManagedObject {}

extension MediaBase {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaBase> {
        NSFetchRequest<MediaBase>(entityName: "MediaBase")
    }

    @NSManaged public var id: UUID
    @NSManaged public var url: String  // Remote URL (https://...)
    @NSManaged public var position: Int16  // Ordering in a list/grid.

    // UX.
    @NSManaged public var mimeType: String?  // Example: image/jpeg.
    @NSManaged public var averageColorHex: String?
}

extension MediaBase {
    var inferredKind: MediaKind {
        let m = mimeType?.lowercased() ?? ""
        if m.hasPrefix("image/") { return .image }
        if m.hasPrefix("video/") { return .video }
        if m.hasPrefix("audio/") { return .audio }
        return .other
    }
}

// Local & Cloud Storage:
extension MediaBase: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
