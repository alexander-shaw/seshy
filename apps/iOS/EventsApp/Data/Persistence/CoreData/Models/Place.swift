//
//  Place.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

// MARK: Human-readable location.  A reusable venue/address with coordinates.

import Foundation
import CoreData

@objc(Place)
public class Place: NSManagedObject {}

extension Place {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var name: String?
    @NSManaged public var details: String?

    @NSManaged public var streetAddress: String?
    @NSManaged public var city: String?
    @NSManaged public var stateRegion: String?

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

    // Relationships:
    @NSManaged public var events: Set<PartyEvent>
}
