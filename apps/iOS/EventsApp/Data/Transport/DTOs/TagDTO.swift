//
//  TagDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct TagDTO: Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let slug: String
    public let categoryRaw: Int16
    public let systemDefined: Bool
    public let isActive: Bool
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}
