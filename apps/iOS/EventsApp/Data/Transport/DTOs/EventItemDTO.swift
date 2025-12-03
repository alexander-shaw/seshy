//
//  EventItemDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct EventItemDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let scheduleStatusRaw: Int16
    public let name: String
    public let details: String?
    public let themePrimaryHex: String?
    public let themeSecondaryHex: String?
    public let themeMode: String?
    public let startTime: Date?
    public let endTime: Date?
    public let durationMinutes: Int64?
    public let isAllDay: Bool
    public let locationID: UUID?
    public let maxCapacity: Int64
    public let visibilityRaw: Int16
    public let inviteLink: String?
    
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public let syncStatusRaw: Int16
    public let lastCloudSyncedAt: Date?
    public let schemaVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case scheduleStatusRaw = "schedule_status_raw"
        case name
        case details
        case themePrimaryHex = "theme_primary_hex"
        case themeSecondaryHex = "theme_secondary_hex"
        case themeMode = "theme_mode"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case isAllDay = "is_all_day"
        case locationID = "location_id"
        case maxCapacity = "max_capacity"
        case visibilityRaw = "visibility_raw"
        case inviteLink = "invite_link"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncStatusRaw = "sync_status_raw"
        case lastCloudSyncedAt = "last_cloud_synced_at"
        case schemaVersion = "schema_version"
    }
    
    public init(
        id: UUID,
        scheduleStatusRaw: Int16,
        name: String,
        details: String?,
        themePrimaryHex: String? = nil,
        themeSecondaryHex: String? = nil,
        themeMode: String? = nil,
        startTime: Date?,
        endTime: Date?,
        durationMinutes: Int64?,
        isAllDay: Bool,
        locationID: UUID?,
        maxCapacity: Int64,
        visibilityRaw: Int16,
        inviteLink: String?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        syncStatusRaw: Int16,
        lastCloudSyncedAt: Date? = nil,
        schemaVersion: Int = 1
    ) {
        self.id = id
        self.scheduleStatusRaw = scheduleStatusRaw
        self.name = name
        self.details = details
        self.themePrimaryHex = themePrimaryHex
        self.themeSecondaryHex = themeSecondaryHex
        self.themeMode = themeMode
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isAllDay = isAllDay
        self.locationID = locationID
        self.maxCapacity = maxCapacity
        self.visibilityRaw = visibilityRaw
        self.inviteLink = inviteLink
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatusRaw = syncStatusRaw
        self.lastCloudSyncedAt = lastCloudSyncedAt
        self.schemaVersion = schemaVersion
    }
}
