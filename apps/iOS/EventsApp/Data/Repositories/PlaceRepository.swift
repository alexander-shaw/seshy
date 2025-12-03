//
//  PlaceRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData

public protocol PlaceRepository {
    func createPlace(name: String) async throws -> Place
    func getPlace(by id: UUID) async throws -> Place?
    func getAllPlaces() async throws -> [Place]
    func updatePlace(_ place: Place) async throws -> Place
    func deletePlace(_ place: Place) async throws
}

public final class CorePlaceRepository: PlaceRepository {
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    public func createPlace(name: String) async throws -> Place {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataStack.viewContext.perform {
                do {
                    let place = Place(context: self.coreDataStack.viewContext)
                    
                    // Set UUID first to avoid bridging issues
                    let newUUID = UUID()
                    place.id = newUUID
                    place.name = name
                    
                    // Set SyncTrackable attributes
                    let now = Date()
                    place.createdAt = now
                    place.updatedAt = now
                    place.deletedAt = nil
                    place.syncStatusRaw = SyncStatus.pending.rawValue
                    place.lastCloudSyncedAt = nil
                    place.schemaVersion = 1
                    
                    // Save immediately to get permanent objectID
                    try self.coreDataStack.viewContext.save()
                    
                    continuation.resume(returning: place)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    public func getPlace(by id: UUID) async throws -> Place? {
        try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<Place> = Place.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    
                    let place = try context.fetch(request).first
                    continuation.resume(returning: place)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getAllPlaces() async throws -> [Place] {
        try await withCheckedThrowingContinuation { continuation in
            let context = coreDataStack.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<Place> = Place.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Place.name, ascending: true)]
                    
                    let places = try context.fetch(request)
                    continuation.resume(returning: places)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    public func updatePlace(_ place: Place) async throws -> Place {
        let objectID = place.objectID
        let updatedName = place.name
        
        return try await coreDataStack.performBackgroundTask { context in
            guard let placeInContext = try? context.existingObject(with: objectID) as? Place else {
                throw RepositoryError.placeNotFound
            }
            
            placeInContext.name = updatedName
            placeInContext.updatedAt = Date()
            placeInContext.syncStatusRaw = SyncStatus.pending.rawValue
            try context.save()
            return placeInContext
        }
    }
    
    public func deletePlace(_ place: Place) async throws {
        let objectID = place.objectID
        
        try await coreDataStack.performBackgroundTask { context in
            guard let placeInContext = try? context.existingObject(with: objectID) as? Place else {
                throw RepositoryError.placeNotFound
            }
            context.delete(placeInContext)
            try context.save()
        }
    }
}
