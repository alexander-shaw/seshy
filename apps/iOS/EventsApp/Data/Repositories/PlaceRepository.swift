//
//  PlaceRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreLocation
import CoreDomain

protocol PlaceRepository {
    func createPlace(name: String?, details: String?, streetAddress: String?, city: String?, stateRegion: String?, roomNumber: String?, latitude: Double, longitude: Double, radius: Double, maxCapacity: Int64) async throws -> Place
    func getPlace(by id: UUID) async throws -> Place?
    func getAllPlaces() async throws -> [Place]
    func searchPlaces(query: String) async throws -> [Place]
    func findPlacesNearby(latitude: Double, longitude: Double, radius: Double) async throws -> [Place]
    func updatePlace(_ place: Place) async throws -> Place
    func deletePlace(_ place: Place) async throws
    func getPlacesWithEvents() async throws -> [Place]
    func findOrCreatePlace(name: String?, details: String?, streetAddress: String?, city: String?, stateRegion: String?, roomNumber: String?, latitude: Double, longitude: Double, radius: Double, maxCapacity: Int64) async throws -> Place
}

final class CoreDataPlaceRepository: PlaceRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createPlace(name: String? = nil, details: String? = nil, streetAddress: String? = nil, city: String? = nil, stateRegion: String? = nil, roomNumber: String? = nil, latitude: Double, longitude: Double, radius: Double = 10.0, maxCapacity: Int64 = 100) async throws -> Place {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let place = Place(context: self.coreDataStack.viewContext)
                    
                    // Set UUID first to avoid bridging issues.
                    let newUUID = UUID()
                    place.setValue(newUUID, forKey: "id")
                    
                    place.createdAt = Date()
                    place.updatedAt = Date()
                    place.name = name
                    place.details = details
                    place.streetAddress = streetAddress
                    place.city = city
                    place.stateRegion = stateRegion
                    place.roomNumber = roomNumber
                    place.latitude = latitude
                    place.longitude = longitude
                    place.radius = radius
                    place.maxCapacity = NSNumber(value: maxCapacity)
                    place.syncStatus = .pending
                    
                    try self.coreDataStack.viewContext.save()
                    continuation.resume(returning: place)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func getPlace(by id: UUID) async throws -> Place? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let places = try context.fetch(request)
            return places.first
        }
    }
    
    func getAllPlaces() async throws -> [Place] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Place.name, ascending: true)]
            
            let places = try context.fetch(request)
            return places
        }
    }
    
    func searchPlaces(query: String) async throws -> [Place] {
        // Ensure query is properly formatted and not empty.
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }
        
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            
            // Create predicate with proper nil handling - search across all relevant fields.
            request.predicate = NSPredicate(format: "(name != nil AND name CONTAINS[cd] %@) OR (details != nil AND details CONTAINS[cd] %@) OR (streetAddress != nil AND streetAddress CONTAINS[cd] %@) OR (city != nil AND city CONTAINS[cd] %@) OR (stateRegion != nil AND stateRegion CONTAINS[cd] %@)", trimmedQuery, trimmedQuery, trimmedQuery, trimmedQuery, trimmedQuery)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Place.name, ascending: true)]
            
            let places = try context.fetch(request)
            return places
        }
    }
    
    func findPlacesNearby(latitude: Double, longitude: Double, radius: Double) async throws -> [Place] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            
            // Calculate approximate bounding box for the radius.
            let latDelta = radius / 111000.0  // Rough conversion: 1 degree latitude ≈ 111km.
            let lonDelta = radius / (111000.0 * cos(latitude * .pi / 180.0))  // Adjust for longitude.

            let minLat = latitude - latDelta
            let maxLat = latitude + latDelta
            let minLon = longitude - lonDelta
            let maxLon = longitude + lonDelta
            
            request.predicate = NSPredicate(format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f", 
                                          minLat, maxLat, minLon, maxLon)
            
            let places = try context.fetch(request)
            
            // Filter by actual distance (more accurate than bounding box).
            let filteredPlaces = places.filter { place in
                let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
                let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
                return location.distance(from: targetLocation) <= radius
            }
            
            return filteredPlaces
        }
    }
    
    func updatePlace(_ place: Place) async throws -> Place {
        return try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            place.updatedAt = Date()
            place.syncStatus = .pending
            
            try context.save()
            return place
        }
    }
    
    func deletePlace(_ place: Place) async throws {
        try await coreDataStack.performBackgroundTask { context in
            context.delete(place)
            try context.save()
        }
    }
    
    func getPlacesWithEvents() async throws -> [Place] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            request.predicate = NSPredicate(format: "events.@count > 0")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Place.name, ascending: true)]
            
            let places = try context.fetch(request)
            return places
        }
    }
    
    func findOrCreatePlace(name: String? = nil, details: String? = nil, streetAddress: String? = nil, city: String? = nil, stateRegion: String? = nil, roomNumber: String? = nil, latitude: Double, longitude: Double, radius: Double = 10.0, maxCapacity: Int64 = 100) async throws -> Place {
        // First, try to find an existing place at the same coordinates.
        let existingPlace = try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Place> = Place.fetchRequest()
            let tolerance = 0.0001  // Very small tolerance for coordinate matching.
            request.predicate = NSPredicate(format: "ABS(latitude - %f) < %f AND ABS(longitude - %f) < %f", latitude, tolerance, longitude, tolerance)
            request.fetchLimit = 1
            
            let existingPlaces = try context.fetch(request)
            return existingPlaces.first
        }
        
        if let existingPlace = existingPlace {
            // Update existing place with new information, if provided.
            let updatedPlace = try await coreDataStack.performBackgroundTask { context in
                if let name = name, !name.isEmpty {
                    existingPlace.name = name
                }
                if let details = details, !details.isEmpty {
                    existingPlace.details = details
                }
                if let streetAddress = streetAddress, !streetAddress.isEmpty {
                    existingPlace.streetAddress = streetAddress
                }
                if let city = city, !city.isEmpty {
                    existingPlace.city = city
                }
                if let stateRegion = stateRegion, !stateRegion.isEmpty {
                    existingPlace.stateRegion = stateRegion
                }
                if let roomNumber = roomNumber, !roomNumber.isEmpty {
                    existingPlace.roomNumber = roomNumber
                }
                existingPlace.radius = radius
                existingPlace.maxCapacity = NSNumber(value: maxCapacity)
                
                existingPlace.updatedAt = Date()
                existingPlace.syncStatus = .pending
                
                try context.save()
                return existingPlace
            }
            return updatedPlace
        } else {
            // Create a new place.
            return try await createPlace(name: name, details: details, streetAddress: streetAddress, city: city, stateRegion: stateRegion, roomNumber: roomNumber, latitude: latitude, longitude: longitude, radius: radius, maxCapacity: maxCapacity)
        }
    }
}
