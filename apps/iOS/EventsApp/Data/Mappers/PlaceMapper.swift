//
//  PlaceMapper.swift
//  EventsApp
//
//  Created by Шоу on 11/25/25.
//

import Foundation
import CoreData

/// Lightweight representation of a Place for UI state (before creating Core Data object).
public struct PlaceRepresentation: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Place Conversion
extension PlaceRepresentation {
    /// Creates a Core Data Place managed object from this representation.
    func makeManagedObject(in context: NSManagedObjectContext, userID: UUID? = nil) -> Place {
        let place = Place(context: context)
        place.id = id
        place.name = name
        
        // Set SyncTrackable attributes
        let now = Date()
        place.createdAt = now
        place.updatedAt = now
        place.deletedAt = nil
        place.syncStatusRaw = SyncStatus.pending.rawValue
        place.lastCloudSyncedAt = nil
        place.schemaVersion = 1
        
        return place
    }
    
    /// Creates a PlaceRepresentation from a Core Data Place.
    init(from place: Place) {
        self.id = place.id
        self.name = place.name
    }
}

extension Place {
    /// Creates a lightweight PlaceRepresentation from this Core Data Place.
    func toPlaceRepresentation() -> PlaceRepresentation {
        PlaceRepresentation(from: self)
    }
}

