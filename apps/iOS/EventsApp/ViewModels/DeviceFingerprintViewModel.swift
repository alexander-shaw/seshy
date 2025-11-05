//
//  DeviceFingerprintViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import UIKit

@MainActor
final class DeviceFingerprintViewModel: ObservableObject {
    @Published var regionCode: String = Locale.current.region?.identifier ?? "US"
    @Published var timezone: String = TimeZone.current.identifier
    @Published var lastActiveAt: Date = Date()
    @Published var loginAttemptCount: Int = 0
    @Published var isLockedOut: Bool = false
    @Published var lockoutUntil: Date?

    private let context: NSManagedObjectContext
    private let repository: DeviceFingerprintRepository
    private var deviceFingerprint: DeviceFingerprintDTO?

    private let lockoutThreshold = 5
    private let cooldown: TimeInterval = 60  // 1 minute.

    init(context: NSManagedObjectContext? = nil, repository: DeviceFingerprintRepository? = nil) {
        self.context = context ?? CoreDataStack.shared.viewContext
        self.repository = repository ?? CoreDeviceFingerprintRepository()

        Task {
            // Wait for Core Data store to be ready before attempting any operations.
            do {
                try await CoreDataStack.shared.waitForStore()
                await load()
            } catch {
                print("Failed to wait for Core Data store:  \(error)")
                // Retry once after a short delay.
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                do {
                    try await CoreDataStack.shared.waitForStore()
                    await load()
                } catch {
                    print("Failed to load DeviceFingerprint after retry:  \(error)")
                }
            }
        }
    }

    func load() async {
        // Verify that store is ready before proceeding.
        if !CoreDataStack.shared.isStoreReady {
            print("Core Data store not ready, deferring DeviceFingerprint load.")
            // Tries to wait for store and retry.
            do {
                try await CoreDataStack.shared.waitForStore()
            } catch {
                print("Store still not ready:  \(error)")
                return
            }
        }
        
        do {
            if let existing = try await repository.getCurrentFingerprint() {
                deviceFingerprint = existing
                regionCode = existing.regionCode
                timezone = existing.timezone
                lastActiveAt = existing.lastActiveAt
                loginAttemptCount = Int(existing.loginAttemptCount)
                lockoutUntil = existing.lockoutUntil
                isLockedOut = existing.isLockedOut
            } else {
                let fingerprint = try await repository.createOrUpdateFingerprint()
                deviceFingerprint = fingerprint
                regionCode = fingerprint.regionCode
                timezone = fingerprint.timezone
                lastActiveAt = fingerprint.lastActiveAt
                loginAttemptCount = Int(fingerprint.loginAttemptCount)
                lockoutUntil = fingerprint.lockoutUntil
                isLockedOut = fingerprint.isLockedOut
            }
        } catch {
            print("Failed to fetch DeviceFingerprint:  ", error)
            // If error is related to store not ready, log it specifically
            if let nsError = error as NSError?,
               nsError.domain == "NSPersistentStoreCoordinatorErrorDomain" ||
               nsError.localizedDescription.contains("no persistent stores") {
                print("This error may indicate the store is not fully loaded yet.")
            }
        }
    }

    func registerLoginAttempt() async {
        do {
            try await repository.incrementLoginAttempts()
            await load()  // Refresh the data.
        } catch {
            print("Failed to register login attempt:  ", error)
        }
    }

    func resetAttempts() async {
        do {
            try await repository.resetLoginAttempts()
            await load()
        } catch {
            print("Failed to reset attempts:  ", error)
        }
    }

    func refreshEnvironmentSnapshot() async {
        do {
            try await repository.updateLastActive()
            await load()
        } catch {
            print("Failed to refresh environment snapshot:  ", error)
        }
    }

    func checkIfDeviceIsLockedOut() async -> Bool {
        do {
            let result = try await repository.isDeviceLockedOut()
            return result.locked
        } catch {
            print("Failed to check device lockout status:  ", error)
            return false
        }
    }
}
