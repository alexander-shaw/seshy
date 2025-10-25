//
//  TagRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

public protocol TagRepository: Sendable {
    func createTag(name: String, slug: String, category: TagCategory, systemDefined: Bool, isActive: Bool) async throws -> Tag
    func getTag(by id: UUID) async throws -> Tag?
    func getTag(by slug: String) async throws -> Tag?
    func getAllTags() async throws -> [Tag]
    func getActiveTags() async throws -> [Tag]
    func getTagsByCategory(_ category: TagCategory) async throws -> [Tag]
    func getSystemDefinedTags() async throws -> [Tag]
    func getUserDefinedTags() async throws -> [Tag]
    func searchTags(query: String) async throws -> [Tag]
    func updateTag(_ tag: Tag) async throws -> Tag?
    func deleteTag(_ tagID: UUID) async throws
    func activateTag(_ tagID: UUID) async throws -> Tag?
    func deactivateTag(_ tagID: UUID) async throws -> Tag?
    func getTagsForEvent(_ eventID: UUID) async throws -> [Tag]
    func addTagToEvent(_ tagID: UUID, eventID: UUID) async throws
    func removeTagFromEvent(_ tagID: UUID, eventID: UUID) async throws
    func findOrCreateTag(name: String, category: TagCategory, systemDefined: Bool) async throws -> Tag
}

final class CoreDataTagRepository: TagRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createTag(name: String, slug: String, category: TagCategory, systemDefined: Bool = false, isActive: Bool = true) async throws -> Tag {
        return try await coreDataStack.performBackgroundTask { context in
            let tag = Tag(context: context)
            tag.id = UUID()
            tag.createdAt = Date()
            tag.updatedAt = Date()
            tag.name = name
            tag.slug = slug
            tag.categoryRaw = category.rawValue
            tag.systemDefined = systemDefined
            tag.isActive = isActive
            tag.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return tag
        }
    }
    
    func getTag(by id: UUID) async throws -> Tag? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let tags = try context.fetch(request)
            return tags.first
        }
    }
    
    func getTag(by slug: String) async throws -> Tag? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "slug == %@", slug)
            request.fetchLimit = 1
            
            let tags = try context.fetch(request)
            return tags.first
        }
    }
    
    func getAllTags() async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Tag.categoryRaw, ascending: true),
                NSSortDescriptor(keyPath: \Tag.name, ascending: true)
            ]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func getActiveTags() async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Tag.categoryRaw, ascending: true),
                NSSortDescriptor(keyPath: \Tag.name, ascending: true)
            ]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func getTagsByCategory(_ category: TagCategory) async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "categoryRaw == %d AND isActive == YES", category.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func getSystemDefinedTags() async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "systemDefined == YES AND isActive == YES")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \Tag.categoryRaw, ascending: true),
                NSSortDescriptor(keyPath: \Tag.name, ascending: true)
            ]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func getUserDefinedTags() async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "systemDefined == NO AND isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func searchTags(query: String) async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "(name CONTAINS[cd] %@ OR slug CONTAINS[cd] %@) AND isActive == YES", query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func updateTag(_ tag: Tag) async throws -> Tag? {
        return try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            tag.updatedAt = Date()
            tag.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return tag
        }
    }
    
    func deleteTag(_ tagID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            request.fetchLimit = 1
            
            if let tag = try context.fetch(request).first {
                context.delete(tag)
                try context.save()
            }
        }
    }
    
    func activateTag(_ tagID: UUID) async throws -> Tag? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            request.fetchLimit = 1
            
            guard let tag = try context.fetch(request).first else { return nil }
            
            tag.isActive = true
            tag.updatedAt = Date()
            tag.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return tag
        }
    }
    
    func deactivateTag(_ tagID: UUID) async throws -> Tag? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            request.fetchLimit = 1
            
            guard let tag = try context.fetch(request).first else { return nil }
            
            tag.isActive = false
            tag.updatedAt = Date()
            tag.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return tag
        }
    }
    
    func getTagsForEvent(_ eventID: UUID) async throws -> [Tag] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "ANY events.id == %@", eventID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let tags = try context.fetch(request)
            return tags
        }
    }
    
    func addTagToEvent(_ tagID: UUID, eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Fetch the tag.
            let tagRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            tagRequest.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            tagRequest.fetchLimit = 1
            
            // Fetch the event.
            let eventRequest: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let tag = try context.fetch(tagRequest).first,
                  let event = try context.fetch(eventRequest).first else { return }
            
            var eventTags = event.tags ?? Set<Tag>()
            eventTags.insert(tag)
            event.tags = eventTags
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
        }
    }
    
    func removeTagFromEvent(_ tagID: UUID, eventID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Fetch the tag.
            let tagRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            tagRequest.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            tagRequest.fetchLimit = 1
            
            // Fetch the event.
            let eventRequest: NSFetchRequest<UserEvent> = UserEvent.fetchRequest()
            eventRequest.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            eventRequest.fetchLimit = 1
            
            guard let tag = try context.fetch(tagRequest).first,
                  let event = try context.fetch(eventRequest).first else { return }
            
            var eventTags = event.tags ?? Set<Tag>()
            eventTags.remove(tag)
            event.tags = eventTags
            event.updatedAt = Date()
            event.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
        }
    }
    
    func findOrCreateTag(name: String, category: TagCategory, systemDefined: Bool = false) async throws -> Tag {
        let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
        
        // First try to find existing tag by slug.
        if let existingTag = try await getTag(by: slug) {
            return existingTag
        }
        
        // Create a new tag.
        return try await createTag(name: name, slug: slug, category: category, systemDefined: systemDefined)
    }
}
