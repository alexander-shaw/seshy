//
//  MediaBaseDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct MediaBaseDTO: Codable, Sendable, Equatable {
    public let url: String
    public let position: Int16
    public let mimeType: String?
    public let averageColorHex: String?
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}

// Event Media DTO:
public struct EventMediaDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let url: String
    public let position: Int16
    public let mimeType: String?
    public let averageColorHex: String?
    public let eventID: UUID
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}

// User Media DTO:
public struct UserMediaDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let url: String
    public let position: Int16
    public let mimeType: String?
    public let averageColorHex: String?
    public let ownerProfileID: UUID
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}

// Profile Media DTO:
public struct ProfileMediaDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let url: String
    public let position: Int16
    public let mimeType: String?
    public let averageColorHex: String?
    public let profileID: UUID
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}


