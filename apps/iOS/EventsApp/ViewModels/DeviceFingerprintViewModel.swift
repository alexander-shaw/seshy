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
        self.repository = repository ?? CoreDataDeviceFingerprintRepository()

        Task {
            await load()
        }
    }

    func load() async {
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
