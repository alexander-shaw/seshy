//
//  MediaBase.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

// MARK: Abstract base.

import Foundation
import CoreData

@objc(MediaBase)
public class MediaBase: NSManagedObject {}

public extension MediaBase {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MediaBase> {
        NSFetchRequest<MediaBase>(entityName: "MediaBase")
    }

    // Shared Attributes:
    @NSManaged var id: UUID
    @NSManaged var url: String  // CDN or signed URL.
    @NSManaged var mimeType: String?
    @NSManaged var position: Int16  // Ordering within a set.
    @NSManaged var averageColorHex: String?
    @NSManaged var width: NSNumber?  // Optional Int32.  Nil for audio/docs.
    @NSManaged var height: NSNumber?  // Optional Int32.
    @NSManaged var durationMilliseconds: NSNumber?  // Optional Int64.
    @NSManaged var takenAt: Date?
}

// Shared conveniences & MediaLike conformance for all subclasses
extension MediaBase: MediaLike {
    public var urlString: String { url }
    public var widthValue: Int? { width?.intValue }
    public var heightValue: Int? { height?.intValue }
    public var durationMillisecondsValue: Int? { durationMilliseconds?.intValue }
}
