//
//  VibeRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

public protocol VibeRepository: Sendable {
    func createVibe(name: String, slug: String, category: VibeCategory, systemDefined: Bool, isActive: Bool) async throws -> Vibe
    func getVibe(by id: UUID) async throws -> Vibe?
    func getVibe(by slug: String) async throws -> Vibe?
    func getAllVibes() async throws -> [Vibe]
    func getActiveVibes() async throws -> [Vibe]
    func getVibesByCategory(_ category: VibeCategory) async throws -> [Vibe]
    func getSystemDefinedVibes() async throws -> [Vibe]
    func getUserDefinedVibes() async throws -> [Vibe]
    func searchVibes(query: String) async throws -> [Vibe]
    func updateVibe(_ vibe: Vibe) async throws -> Vibe?
    func deleteVibe(_ vibeID: UUID) async throws
    func activateVibe(_ vibeID: UUID) async throws -> Vibe?
    func deactivateVibe(_ vibeID: UUID) async throws -> Vibe?
    func getVibesForEvent(_ eventID: UUID) async throws -> [Vibe]
    func addVibeToEvent(_ vibeID: UUID, eventID: UUID) async throws
    func removeVibeFromEvent(_ vibeID: UUID, eventID: UUID) async throws
    func findOrCreateVibe(name: String, category: VibeCategory, systemDefined: Bool) async throws -> Vibe
}

final class CoreVibeRepository: VibeRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createVibe(name: String, slug: String, category: VibeCategory, systemDefined: Bool, isActive: Bool) async throws -> Vibe {
        return try await coreDataStack.performBackgroundTask { context in
            let vibe = Vibe(context: context)
            vibe.id = UUID()
            vibe.createdAt = Date()
            vibe.updatedAt = Date()
            vibe.name = name
            vibe.slug = slug
            vibe.categoryRaw = category.rawValue
            vibe.systemDefined = systemDefined
            vibe.isActive = isActive
            vibe.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return vibe
        }
    }
    
    func getVibe(by id: UUID) async throws -> Vibe? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let vibes = try context.fetch(request)
            return vibes.first
        }
    }
    
    func getVibe(by slug: String) async throws -> Vibe? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "slug == %@", slug)
            request.fetchLimit = 1
            
            let vibes = try context.fetch(request)
            return vibes.first
        }
    }
    
    func getAllVibes() async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Vibe.categoryRaw, ascending: true),
                NSSortDescriptor(keyPath: \Vibe.name, ascending: true)
            ]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func getActiveVibes() async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Vibe.categoryRaw, ascending: true),
                NSSortDescriptor(keyPath: \Vibe.name, ascending: true)
            ]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func getVibesByCategory(_ category: VibeCategory) async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "categoryRaw == %d AND isActive == YES", category.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Vibe.name, ascending: true)]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func getSystemDefinedVibes() async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "systemDefined == YES AND isActive == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Vibe.categoryRaw, ascending: true),
                NSSortDescriptor(keyPath: \Vibe.name, ascending: true)
            ]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func getUserDefinedVibes() async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "systemDefined == NO AND isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Vibe.name, ascending: true)]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func searchVibes(query: String) async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "(name CONTAINS[cd] %@ OR slug CONTAINS[cd] %@) AND isActive == YES", query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Vibe.name, ascending: true)]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func updateVibe(_ vibe: Vibe) async throws -> Vibe? {
        return try await coreDataStack.performBackgroundTask { context in
            guard let contextVibe = try context.existingObject(with: vibe.objectID) as? Vibe else {
                return nil
            }
            
            contextVibe.updatedAt = Date()
            contextVibe.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return contextVibe
        }
    }
    
    func deleteVibe(_ vibeID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", vibeID as CVarArg)
            request.fetchLimit = 1
            
            if let vibe = try context.fetch(request).first {
                context.delete(vibe)
                try context.save()
            }
        }
    }
    
    func activateVibe(_ vibeID: UUID) async throws -> Vibe? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", vibeID as CVarArg)
            request.fetchLimit = 1
            
            guard let vibe = try context.fetch(request).first else { return nil }
            
            vibe.isActive = true
            vibe.updatedAt = Date()
            vibe.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return vibe
        }
    }
    
    func deactivateVibe(_ vibeID: UUID) async throws -> Vibe? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", vibeID as CVarArg)
            request.fetchLimit = 1
            
            guard let vibe = try context.fetch(request).first else { return nil }
            
            vibe.isActive = false
            vibe.updatedAt = Date()
            vibe.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return vibe
        }
    }
    
    func getVibesForEvent(_ eventID: UUID) async throws -> [Vibe] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            request.predicate = NSPredicate(format: "ANY events.id == %@", eventID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Vibe.name, ascending: true)]
            
            let vibes = try context.fetch(request)
            return vibes
        }
    }
    
    func addVibeToEvent(_ vibeID: UUID, eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let vibeRequest: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            vibeRequest.predicate = NSPredicate(format: "id == %@", vibeID as CVarArg)
            vibeRequest.fetchLimit = 1
            
            let eventRequest: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let vibe = try context.fetch(vibeRequest).first,
                  let event = try context.fetch(eventRequest).first else { return }
            
            var eventVibes = event.vibes ?? Set<Vibe>()
            eventVibes.insert(vibe)
            event.vibes = eventVibes
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
        }
    }
    
    func removeVibeFromEvent(_ vibeID: UUID, eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let vibeRequest: NSFetchRequest<Vibe> = Vibe.fetchRequest()
            vibeRequest.predicate = NSPredicate(format: "id == %@", vibeID as CVarArg)
            vibeRequest.fetchLimit = 1
            
            let eventRequest: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let vibe = try context.fetch(vibeRequest).first,
                  let event = try context.fetch(eventRequest).first else { return }
            
            var eventVibes = event.vibes ?? Set<Vibe>()
            eventVibes.remove(vibe)
            event.vibes = eventVibes
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
        }
    }
    
    func findOrCreateVibe(name: String, category: VibeCategory, systemDefined: Bool) async throws -> Vibe {
        let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
        
        if let existingVibe = try await getVibe(by: slug) {
            return existingVibe
        }
        
        return try await createVibe(name: name, slug: slug, category: category, systemDefined: systemDefined, isActive: true)
    }
}
