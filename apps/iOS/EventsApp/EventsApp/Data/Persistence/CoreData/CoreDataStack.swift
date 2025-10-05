//
//  CoreDataStack.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import CoreData

// MARK: Infrastructure-only: owns the container and create contexts.
// MARK: Create a single instance at app start and inject contexts into repositories/view models.
final class CoreDataStack {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(modelName: String = "EventsApp", inMemory: Bool = false) {
        container = NSPersistentContainer(name: modelName)

        // Store description + lightweight migrations.
        let desc: NSPersistentStoreDescription = {
            if inMemory {
                let d = NSPersistentStoreDescription()
                d.type = NSInMemoryStoreType
                return d
            } else {
                return container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
            }
        }()
        desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        desc.shouldAddStoreAsynchronously = true
        container.persistentStoreDescriptions = [desc]

        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Core Data load error:  \(error)") }
        }

        let vc = container.viewContext
        vc.name = "viewContext"
        vc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        vc.automaticallyMergesChangesFromParent = true
        vc.shouldDeleteInaccessibleFaults = true
    }

    // An isolated background context (preferred for imports/sync).
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.name = "bgContext-\(UUID().uuidString.prefix(6))"
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }

    // Closure helper.
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // Async/await helper that returns a value.
    @discardableResult
    func performBackgroundTask<T>(_ work: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            container.performBackgroundTask { ctx in
                do { cont.resume(returning: try work(ctx)) }
                catch { cont.resume(throwing: error) }
            }
        }
    }
}

// MARK: Small helpers.
extension NSManagedObjectContext {
    func saveIfNeeded() throws { if hasChanges { try save() } }

    func performAndWaitThrowing<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        performAndWait {
            do { result = .success(try block()) }
            catch { result = .failure(error) }
        }
        return try result.get()
    }
}
