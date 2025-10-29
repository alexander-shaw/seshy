//
//  InviteDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct InviteDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userID: UUID
    public let typeRaw: Int16
    public let statusRaw: Int16
    public let token: String?
    public let expiresAt: Date?
    public let eventID: UUID
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}

