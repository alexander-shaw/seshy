//
//  UserSettingsMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

// Provides mapping functions between Core Data UserSettings entities and UserSettingsDTOs.
// Used for converting between local storage format and transport/cloud format.

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapUserSettingsToDTO(_ obj: UserSettings) -> UserSettingsDTO {
    UserSettingsDTO(
        id: obj.id,
        appearanceModeRaw: obj.appearanceModeRaw,
        unitsRaw: obj.preferredUnitsRaw,
        mapStyleRaw: obj.mapStyleRaw,
        mapCenterLatitude: obj.mapCenterLatitude,
        mapCenterLongitude: obj.mapCenterLongitude,
        mapZoomLevel: Double(obj.mapZoomLevel),
        mapEndDate: obj.mapEndDate,
        mapMaxDistance: nil,  // TODO: Store in Core Data model.
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension UserSettings {
    // Apply values from a DTO (call inside the context's perform block).
    func apply(_ dto: UserSettingsDTO) {
        id = dto.id
        mapStyleRaw = dto.mapStyleRaw
        appearanceModeRaw = dto.appearanceModeRaw
        preferredUnitsRaw = dto.unitsRaw
        mapCenterLatitude = dto.mapCenterLatitude
        mapCenterLongitude = dto.mapCenterLongitude
        mapZoomLevel = Int16(dto.mapZoomLevel)
        mapEndDate = dto.mapEndDate
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by your sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserSettingsDTO) -> UserSettings {
        let obj = UserSettings(context: ctx)
        obj.apply(dto)
        return obj
    }
}
