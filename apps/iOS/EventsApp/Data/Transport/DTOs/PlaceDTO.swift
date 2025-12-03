//
//  PlaceDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct PlaceDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int16
}
