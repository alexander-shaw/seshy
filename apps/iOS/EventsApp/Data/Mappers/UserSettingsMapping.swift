//
//  UserSettingsMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapUserSettingsToDTO(_ obj: UserSettings) -> UserSettingsDTO {
    UserSettingsDTO(
        id: obj.id,
        appearanceModeRaw: obj.appearanceModeRaw,
        mapStyleRaw: obj.mapStyleRaw,
        mapCenterLatitude: obj.mapCenterLatitude,
        mapCenterLongitude: obj.mapCenterLongitude,
        mapZoomLevel: Double(obj.mapZoomLevel),
        mapStartDate: obj.mapStartDate,
        mapEndDate: obj.mapEndDate,
        mapMaxDistance: obj.mapMaxDistance?.doubleValue,
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
        mapCenterLatitude = dto.mapCenterLatitude
        mapCenterLongitude = dto.mapCenterLongitude
        mapZoomLevel = Int16(dto.mapZoomLevel)
        mapStartDate = dto.mapStartDate
        mapEndDate = dto.mapEndDate
        mapMaxDistance = dto.mapMaxDistance.map { NSNumber(value: $0) }
        updatedAt = dto.updatedAt
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: UserSettingsDTO) -> UserSettings {
        let obj = UserSettings(context: ctx)
        obj.apply(dto)
        return obj
    }
}

// MARK: - CONFLICT RESOLUTION:
// Upserts settings with conflict resolution.
public func upsertSettings(
    from dto: UserSettingsDTO,
    policy: ConflictRule,
    in ctx: NSManagedObjectContext,
    user: DeviceUser
) throws {
    // Finds existing settings by ID or by user relationship.
    let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@ OR user == %@", dto.id as CVarArg, user)
    request.fetchLimit = 1
    
    let existing = try ctx.fetch(request).first
    
    if let existing = existing {
        // Update existing with conflict resolution.
        switch policy {
        case .serverWins:
            // Always uses server values.
            existing.apply(dto)
            existing.createdAt = existing.createdAt  // Preserves original createdAt.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
            
        case .clientWins:
            // Keeps existing values if conflict detected.
            if existing.updatedAt > dto.updatedAt {
                // Client is newer, keep existing.
                existing.lastCloudSyncedAt = Date()
                existing.syncStatus = .synced
            } else {
                // Server is newer or equal, but policy says client wins - keep existing.
                existing.lastCloudSyncedAt = Date()
                existing.syncStatus = .synced
            }
            
        case .lastWriteWins:
            // Compares updatedAt timestamps.
            if dto.updatedAt >= existing.updatedAt {
                // Server is newer or equal, use server values
                existing.apply(dto)
                existing.createdAt = existing.createdAt  // Preserves original createdAt.
            }
            // If client is newer, keep existing values.
            existing.lastCloudSyncedAt = Date()
            existing.syncStatus = .synced
        }
    } else {
        // Creates new settings.
        let settings = UserSettings(context: ctx)
        settings.id = dto.id
        settings.apply(dto)
        settings.createdAt = Date()
        settings.user = user
        settings.lastCloudSyncedAt = Date()
        settings.syncStatus = .synced
        settings.schemaVersion = 1
    }
}
