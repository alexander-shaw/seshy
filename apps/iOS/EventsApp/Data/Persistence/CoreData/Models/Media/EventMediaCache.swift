//
//  EventMediaCache.swift
//  EventsApp
//
//  Created by Шоу on 10/9/25.
//

// MARK: Inherits MediaBase.

import Foundation
import CoreData

@objc(EventMediaCache)
public class EventMediaCache: MediaBase {}

public extension EventMediaCache {
    @nonobjc class func fetchRequest() -> NSFetchRequest<EventMediaCache> {
        NSFetchRequest<EventMediaCache>(entityName: "EventMediaCache")
    }

    @NSManaged var event: PartyEvent  // Inverse: PartyEvent.previewPhotos (Cascade).
}
