//
//  DeviceFingerprintRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import UIKit

public protocol DeviceFingerprintRepository: Sendable {
    func getCurrentFingerprint() async throws -> DeviceFingerprintDTO?
    func createOrUpdateFingerprint() async throws -> DeviceFingerprintDTO
    func updateLastActive() async throws -> DeviceFingerprintDTO?
    func incrementLoginAttempts() async throws -> DeviceFingerprintDTO?
    func resetLoginAttempts() async throws -> DeviceFingerprintDTO?
    func isDeviceLockedOut() async throws -> (locked: Bool, until: Date?, fingerprint: DeviceFingerprintDTO?)
}

final class CoreDeviceFingerprintRepository: DeviceFingerprintRepository {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - PUBLIC API:
    func getCurrentFingerprint() async throws -> DeviceFingerprintDTO? {
        let deviceId = await currentDeviceIdentifier()
        return try await coreDataStack.performBackgroundTask { ctx in
            try self.fetchCurrent(in: ctx, deviceId: deviceId).map { mapDeviceFingerprintToDTO($0) }
        }
    }

    func createOrUpdateFingerprint() async throws -> DeviceFingerprintDTO {
        let env = await currentEnvironmentSnapshot()
        return try await coreDataStack.performBackgroundTask { ctx in
            // Verify the context has a persistent store coordinator with stores
            guard let coordinator = ctx.persistentStoreCoordinator, !coordinator.persistentStores.isEmpty else {
                throw NSError(
                    domain: "DeviceFingerprintRepository",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Persistent store coordinator has no stores.  Store may not be loaded yet."]
                )
            }
            
            let fp = try self.fetchCurrent(in: ctx, deviceId: env.deviceId) ?? DeviceFingerprint(context: ctx)

            // Check if this is a new entity by seeing if it has a deviceIdentifier set.
            let isNewEntity = fp.deviceIdentifier.isEmpty
            
            // Seed new record if needed.
            if isNewEntity {
                fp.id = UUID()
                fp.createdAt = env.now
                fp.deviceIdentifier = env.deviceId
                fp.loginAttemptCount = 0
                fp.isLockedOut = false
                fp.lockoutUntil = nil
                fp.schemaVersion = 1
            }

            // Upsert common fields.
            fp.updatedAt = env.now
            fp.lastActiveAt = env.now
            fp.deviceModel = env.deviceModel
            fp.systemVersion = env.systemVersion
            fp.appVersion = env.appVersion
            fp.regionCode = env.regionCode
            fp.timezone = env.timezone
            fp.languageCode = env.languageCode

            do {
                try ctx.save()
            } catch {
                print("Error saving DeviceFingerprint: \(error)")
                if let nsError = error as NSError? {
                    print("  Domain:  \(nsError.domain)")
                    print("  Code:  \(nsError.code)")
                    print("  UserInfo:  \(nsError.userInfo)")
                    if coordinator.persistentStores.isEmpty {
                        print("  Persistent store coordinator has no stores!")
                    }
                }
                throw error
            }
            return mapDeviceFingerprintToDTO(fp)
        }
    }

    func updateLastActive() async throws -> DeviceFingerprintDTO? {
        let deviceId = await currentDeviceIdentifier()
        let now = Date()
        return try await coreDataStack.performBackgroundTask { ctx in
            guard let fp = try self.fetchCurrent(in: ctx, deviceId: deviceId) else { return nil }
            fp.lastActiveAt = now
            fp.updatedAt = now
            try ctx.save()
            return mapDeviceFingerprintToDTO(fp)
        }
    }

    func incrementLoginAttempts() async throws -> DeviceFingerprintDTO? {
        let deviceId = await currentDeviceIdentifier()
        let now = Date()
        return try await coreDataStack.performBackgroundTask { ctx in
            guard let fp = try self.fetchCurrent(in: ctx, deviceId: deviceId) else { return nil }
            fp.loginAttemptCount += 1
            fp.lastActiveAt = now
            fp.updatedAt = now

            if fp.loginAttemptCount >= 5 {
                fp.isLockedOut = true
                fp.lockoutUntil = now.addingTimeInterval(60)
            }

            try ctx.save()
            return mapDeviceFingerprintToDTO(fp)
        }
    }

    func resetLoginAttempts() async throws -> DeviceFingerprintDTO? {
        let deviceId = await currentDeviceIdentifier()
        let now = Date()
        return try await coreDataStack.performBackgroundTask { ctx in
            guard let fp = try self.fetchCurrent(in: ctx, deviceId: deviceId) else { return nil }
            fp.loginAttemptCount = 0
            fp.isLockedOut = false
            fp.lockoutUntil = nil
            fp.updatedAt = now
            try ctx.save()
            return mapDeviceFingerprintToDTO(fp)
        }
    }

    func isDeviceLockedOut() async throws -> (locked: Bool, until: Date?, fingerprint: DeviceFingerprintDTO?) {
        let deviceId = await currentDeviceIdentifier()
        return try await coreDataStack.performBackgroundTask { ctx in
            guard let fp = try self.fetchCurrent(in: ctx, deviceId: deviceId) else { return (false, nil, nil) }

            // Expire lockout if needed.
            if fp.isLockedOut, let until = fp.lockoutUntil, until <= Date() {
                fp.isLockedOut = false
                fp.lockoutUntil = nil
                fp.updatedAt = Date()
                try ctx.save()
            }

            return (fp.isLockedOut, fp.lockoutUntil, mapDeviceFingerprintToDTO(fp))
        }
    }

    // MARK: - PRIVATE:
    private func fetchCurrent(in ctx: NSManagedObjectContext, deviceId: String) throws -> DeviceFingerprint? {
        let req: NSFetchRequest<DeviceFingerprint> = DeviceFingerprint.fetchRequest()
        req.predicate = NSPredicate(format: "deviceIdentifier == %@", deviceId)
        req.fetchLimit = 1
        return try ctx.fetch(req).first
    }

    private struct EnvSnapshot {
        let deviceId: String
        let deviceModel: String
        let systemVersion: String
        let appVersion: String
        let regionCode: String
        let timezone: String
        let languageCode: String
        let now: Date
    }

    @MainActor
    private func currentEnvironmentSnapshot() -> EnvSnapshot {
        EnvSnapshot(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            regionCode: Locale.current.region?.identifier ?? "US",
            timezone: TimeZone.current.identifier,
            languageCode: Locale.current.language.languageCode?.identifier ?? "en",
            now: Date()
        )
    }

    @MainActor
    private func currentDeviceIdentifier() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
