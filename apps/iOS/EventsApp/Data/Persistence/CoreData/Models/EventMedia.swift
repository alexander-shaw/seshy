//
//  EventMedia.swift
//  EventsApp
//
//  Created by Шоу on 10/12/25.
//

import CoreData

@objc(EventMedia)
public class EventMedia: MediaBase {}

extension EventMedia {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventMedia> {
        NSFetchRequest<EventMedia>(entityName: "EventMedia")
    }

    @NSManaged public var event: UserEvent
}
