//
//  CoreDataStack.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

// Infrastructure-only: owns the container and create contexts.
// Creates a single instance at app start and inject contexts into repositories/view models.

// Manages the Core Data stack for the application.
// Provides a singleton instance that handles:
// - Persistent container initialization.
// - Background context creation for async operations.
// - Automatic lightweight migrations.
// - Context management and merging policies.

import CoreData

public final class CoreDataStack {
    public static let shared = CoreDataStack()
    
    public let container: NSPersistentContainer
    
    private let storeReadyQueue = DispatchQueue(label: "com.eventsapp.coredata.storeReady")
    private var _isStoreReady: Bool = false
    private var storeLoadError: Error?
    
    public var isStoreReady: Bool {
        storeReadyQueue.sync { _isStoreReady }
    }

    public var viewContext: NSManagedObjectContext { container.viewContext }

    public init(modelName: String = "EventsApp", inMemory: Bool = false) {
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
        desc.shouldAddStoreAsynchronously = false  // Changed to false to ensure store is ready before any save operations.
        container.persistentStoreDescriptions = [desc]

        container.loadPersistentStores { description, error in
            self.storeReadyQueue.sync {
                if let error = error {
                    print("Core Data store load error:  \(error)")
                    print("  Store description:  \(description)")
                    print("  Error details:  \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("  Error domain:  \(nsError.domain)")
                        print("  Error code:  \(nsError.code)")
                        print("  Error userInfo:  \(nsError.userInfo)")
                    }
                    self.storeLoadError = error
                    self._isStoreReady = false
                } else {
                    print("Core Data store loaded successfully.")
                    if let url = description.url {
                        print("  Store location: \(url.absoluteString)")
                    }
                    // Verify persistent store coordinator has stores
                    if self.container.persistentStoreCoordinator.persistentStores.isEmpty {
                        print("WARNING: Persistent store coordinator has no stores after successful load!")
                        self.storeLoadError = NSError(domain: "CoreDataStack", code: -1, userInfo: [NSLocalizedDescriptionKey: "Store coordinator has no persistent stores."])
                        self._isStoreReady = false
                    } else {
                        print("Store coordinator has \(self.container.persistentStoreCoordinator.persistentStores.count) store(s).")
                        self._isStoreReady = true
                        self.storeLoadError = nil
                    }
                }
            }
        }

        let vc = container.viewContext
        vc.name = "viewContext"
        vc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        vc.automaticallyMergesChangesFromParent = true
        vc.shouldDeleteInaccessibleFaults = true
    }
    
    // Waits for the store to be ready, throwing an error if it fails to load.
    public func waitForStore() async throws {
        // If already ready, return immediately.
        if isStoreReady {
            return
        }
        
        // Wait up to 5 seconds for store to be ready.
        let timeout: TimeInterval = 5.0
        let startTime = Date()
        
        while !isStoreReady {
            if Date().timeIntervalSince(startTime) > timeout {
                let error = storeReadyQueue.sync { storeLoadError }
                throw error ?? NSError(domain: "CoreDataStack", code: -1, userInfo: [NSLocalizedDescriptionKey: "Store failed to load within timeout period."])
            }
            try await Task.sleep(nanoseconds: 100_000_000)  // 100 ms.
        }
        
        // Check if there was an error (access safely via queue).
        let error = storeReadyQueue.sync { storeLoadError }
        if let error = error {
            throw error
        }
    }

    // An isolated background context (preferred for imports/sync).
    public func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.name = "bgContext-\(UUID().uuidString.prefix(6))"
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }

    // Closure helper.
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // Async/await helper that returns a value.
    @discardableResult
    public func performBackgroundTask<T>(_ work: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            container.performBackgroundTask { ctx in
                do { cont.resume(returning: try work(ctx)) }
                catch { cont.resume(throwing: error) }
            }
        }
    }
}

// Small helpers.
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
