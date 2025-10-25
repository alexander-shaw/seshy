//
//  H3CellRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreLocation
import CoreDomain

protocol H3CellRepository {
    func createH3Cell(from location: CLLocation, motion: MotionType) async throws -> H3Node
    func getH3Cells(in dateRange: DateInterval?, limit: Int?) async throws -> [H3Node]
    func getH3Cells(at h3Index: Int64, limit: Int?) async throws -> [H3Node]
    func getRecentH3Cells(limit: Int) async throws -> [H3Node]
    func deleteOldH3Cells(olderThan date: Date) async throws -> Int
    func getH3CellCount() async throws -> Int
}

final class CoreDataH3CellRepository: H3CellRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createH3Cell(from location: CLLocation, motion: MotionType = .unknown) async throws -> H3Node {
        return try await coreDataStack.performBackgroundTask { context in
            let h3Node = H3Node.make(in: context, location: location, motion: motion)
            h3Node.createdAt = Date()
            h3Node.updatedAt = Date()
            h3Node.syncStatus = .pending
            
            try context.save()
            return h3Node
        }
    }
    
    func getH3Cells(in dateRange: DateInterval?, limit: Int? = nil) async throws -> [H3Node] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<H3Node> = H3Node.fetchRequest()
            
            if let dateRange = dateRange {
                request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", 
                                              dateRange.start as NSDate, dateRange.end as NSDate)
            }
            
            request.sortDescriptors = [NSSortDescriptor(keyPath: \H3Node.timestamp, ascending: false)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let nodes = try context.fetch(request)
            return nodes
        }
    }
    
    func getH3Cells(at h3Index: Int64, limit: Int? = nil) async throws -> [H3Node] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<H3Node> = H3Node.fetchRequest()
            request.predicate = NSPredicate(format: "h3Index == %lld", h3Index)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \H3Node.timestamp, ascending: false)]
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            let nodes = try context.fetch(request)
            return nodes
        }
    }
    
    func getRecentH3Cells(limit: Int = 100) async throws -> [H3Node] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<H3Node> = H3Node.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \H3Node.timestamp, ascending: false)]
            request.fetchLimit = limit
            
            let nodes = try context.fetch(request)
            return nodes
        }
    }
    
    func deleteOldH3Cells(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<H3Node> = H3Node.fetchRequest()
            request.predicate = NSPredicate(format: "timestamp < %@", date as NSDate)
            
            let oldCells = try context.fetch(request)
            let count = oldCells.count
            
            for cell in oldCells {
                context.delete(cell)
            }
            
            try context.save()
            return count
        }
    }
    
    func getH3CellCount() async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<H3Node> = H3Node.fetchRequest()
            return try context.count(for: request)
        }
    }
}
