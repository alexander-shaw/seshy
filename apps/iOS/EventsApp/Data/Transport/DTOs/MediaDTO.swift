//
//  MediaDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Unified transport/Domain shape for Media.
// Safe to cross actors and send to cloud.
public struct MediaDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let url: String
    public let position: Int16
    public let mimeType: String?
    public let averageColorHex: String?
    
    // Polymorphic owner reference (exactly one should be set)
    public let eventID: UUID?
    public let userProfileID: UUID?
    public let publicProfileID: UUID?
    
    // Sync fields
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
    
    public init(
        id: UUID,
        url: String,
        position: Int16,
        mimeType: String? = nil,
        averageColorHex: String? = nil,
        eventID: UUID? = nil,
        userProfileID: UUID? = nil,
        publicProfileID: UUID? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatusRaw: Int16,
        lastCloudSyncedAt: Date? = nil,
        schemaVersion: Int = 1
    ) {
        self.id = id
        self.url = url
        self.position = position
        self.mimeType = mimeType
        self.averageColorHex = averageColorHex
        self.eventID = eventID
        self.userProfileID = userProfileID
        self.publicProfileID = publicProfileID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatusRaw = syncStatusRaw
        self.lastCloudSyncedAt = lastCloudSyncedAt
        self.schemaVersion = schemaVersion
    }
}
