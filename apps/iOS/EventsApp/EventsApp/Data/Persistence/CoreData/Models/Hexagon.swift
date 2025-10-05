//
//  Hexagon.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// MARK: Represents a hexagonal cell in space and time.
// Uses Uber's H3 library for hierarchical geospatial indexing.

import Foundation
import CoreData

@objc(Hexagon)
public class Hexagon: NSManagedObject, Identifiable {

    @NSManaged public var id: UUID
    @NSManaged public var h3Index: Int64
    @NSManaged public var resolution: Int16
    @NSManaged public var motionTypeRaw: NSNumber?
    @NSManaged public var visitTimestamp: Date

    // MARK: - RELATIONSHIPS:
    // @NSManaged public var places: Set<Place>?

}

/*
extension Hexagon {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Hexagon> {
        return NSFetchRequest<Hexagon>(entityName: "Hexagon")
    }
}
*/
