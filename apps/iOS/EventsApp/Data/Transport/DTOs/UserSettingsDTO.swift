//
//  UserSettingsDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct UserSettingsDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let appearanceModeRaw: Int16
    public let mapStyleRaw: Int16
    public let mapCenterLatitude: Double
    public let mapCenterLongitude: Double
    public let mapZoomLevel: Double
    public let mapStartDate: Date?
    public let mapEndDate: Date?
    public let mapMaxDistance: Double?
    
    public let updatedAt: Date
    public let schemaVersion: Int
}
