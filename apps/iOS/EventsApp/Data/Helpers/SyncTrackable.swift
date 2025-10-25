//
//  SyncTrackable.swift
//  EventsApp
//
//  Created by Шоу on 10/18/25.
//

// MARK: - SyncTrackable Protocol:
// This protocol defines the interface for entities that can be synchronized with cloud storage.
// Provides common properties for tracking sync status, timestamps, and schema versioning.

import Foundation
import CoreData
import CoreDomain

public protocol SyncTrackable {
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
    var deletedAt: Date? { get set }
    var syncStatusRaw: Int16 { get set }
    var lastCloudSyncedAt: Date? { get set }
    var schemaVersion: Int { get set }
    
    var syncStatus: SyncStatus { get set }
}

// MARK: - SyncTrackable Extensions:
extension SyncTrackable {
    public var isDeleted: Bool {
        return deletedAt != nil
    }
    
    public var needsSync: Bool {
        return syncStatus == .pending || syncStatus == .failed
    }
    
    public var hasConflict: Bool {
        return syncStatus == .conflict
    }
}
