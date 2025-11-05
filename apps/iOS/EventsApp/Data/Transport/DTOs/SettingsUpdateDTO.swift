//
//  SettingsUpdateDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

// Updates DTO for push operations (minimal fields for conflict resolution).
public struct SettingsUpdateDTO: Codable, Sendable, Equatable {
    public let appearanceModeRaw: Int16
    public let mapStyleRaw: Int16
    public let mapCenterLatitude: Double
    public let mapCenterLongitude: Double
    public let mapZoomLevel: Double
    public let mapStartDate: Date?
    public let mapEndDate: Date?
    public let mapMaxDistance: Double?
    public let updatedAt: Date
    public let idempotencyKey: String
    
    public init(
        appearanceModeRaw: Int16,
        mapStyleRaw: Int16,
        mapCenterLatitude: Double,
        mapCenterLongitude: Double,
        mapZoomLevel: Double,
        mapStartDate: Date?,
        mapEndDate: Date?,
        mapMaxDistance: Double?,
        updatedAt: Date,
        idempotencyKey: String
    ) {
        self.appearanceModeRaw = appearanceModeRaw
        self.mapStyleRaw = mapStyleRaw
        self.mapCenterLatitude = mapCenterLatitude
        self.mapCenterLongitude = mapCenterLongitude
        self.mapZoomLevel = mapZoomLevel
        self.mapStartDate = mapStartDate
        self.mapEndDate = mapEndDate
        self.mapMaxDistance = mapMaxDistance
        self.updatedAt = updatedAt
        self.idempotencyKey = idempotencyKey
    }
    
    // Creates from LocalSettingsPending and UserSettingsDTO
    public static func from(local: LocalSettingsPending, dto: UserSettingsDTO) -> SettingsUpdateDTO {
        SettingsUpdateDTO(
            appearanceModeRaw: dto.appearanceModeRaw,
            mapStyleRaw: dto.mapStyleRaw,
            mapCenterLatitude: dto.mapCenterLatitude,
            mapCenterLongitude: dto.mapCenterLongitude,
            mapZoomLevel: dto.mapZoomLevel,
            mapStartDate: dto.mapStartDate,
            mapEndDate: dto.mapEndDate,
            mapMaxDistance: dto.mapMaxDistance,
            updatedAt: dto.updatedAt,
            idempotencyKey: local.idempotencyKey
        )
    }
}
