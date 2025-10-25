//
//  DeviceFingerprintMapping.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import CoreData

// CoreData -> DTO (nonisolated by default; safe to call from background context).
@inline(__always)
public func mapDeviceFingerprintToDTO(_ obj: DeviceFingerprint) -> DeviceFingerprintDTO {
    DeviceFingerprintDTO(
        id: obj.id,
        deviceIdentifier: obj.deviceIdentifier,
        deviceModel: obj.deviceModel,
        systemVersion: obj.systemVersion,
        appVersion: obj.appVersion,
        regionCode: obj.regionCode,
        timezone: obj.timezone,
        languageCode: obj.languageCode,
        lastActiveAt: obj.lastActiveAt,
        loginAttemptCount: Int(obj.loginAttemptCount),
        isLockedOut: obj.isLockedOut,
        lockoutUntil: obj.lockoutUntil,
        updatedAt: obj.updatedAt,
        schemaVersion: 1
    )
}

// DTO -> CoreData (create or update within the SAME context).
extension DeviceFingerprint {
    // Apply values from a DTO (call inside the context’s perform block).
    func apply(_ dto: DeviceFingerprintDTO) {
        id = dto.id
        deviceIdentifier = dto.deviceIdentifier
        deviceModel = dto.deviceModel
        systemVersion = dto.systemVersion
        appVersion = dto.appVersion
        regionCode = dto.regionCode
        timezone = dto.timezone
        languageCode = dto.languageCode
        lastActiveAt = dto.lastActiveAt
        loginAttemptCount = Int32(dto.loginAttemptCount)
        isLockedOut = dto.isLockedOut
        lockoutUntil = dto.lockoutUntil
        updatedAt = dto.updatedAt
        // createdAt / deletedAt / syncStatus handled by sync flow.
    }

    // Convenience for inserting new managed object from DTO.
    static func insert(into ctx: NSManagedObjectContext, from dto: DeviceFingerprintDTO) -> DeviceFingerprint {
        let obj = DeviceFingerprint(context: ctx)
        obj.apply(dto)
        return obj
    }
}
