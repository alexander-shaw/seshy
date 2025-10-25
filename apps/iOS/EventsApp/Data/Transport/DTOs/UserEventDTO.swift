//
//  UserEventDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct UserEventDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let scheduleStatusRaw: Int16
    public let name: String
    public let details: String?
    public let brandColor: String
    public let startTime: Date?
    public let endTime: Date?
    public let durationMinutes: Int64?
    public let locationID: UUID
    public let maxCapacity: Int64
    public let visibilityRaw: Int16
    public let inviteLink: String?
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
}
