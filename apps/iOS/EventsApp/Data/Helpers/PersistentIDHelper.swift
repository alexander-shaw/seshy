//
//  PersistentIDHelper.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Keychain-backed device identifier that survives app reinstalls.
final class PersistentIDHelper {
    static let shared = PersistentIDHelper()

    private let key = "com.optify.persistentDeviceID"
    private var cached: UUID?

    // The stable device UUID, generated once and then stored in Keychain.
    var id: UUID {
        if let cached { return cached }

        if let existing = KeychainHelper.getUUID(key: key) {
            cached = existing
            return existing
        }

        // Or create a new one.
        let newID = UUID()
        KeychainHelper.setUUID(key: key, value: newID)
        cached = newID
        return newID
    }
}
