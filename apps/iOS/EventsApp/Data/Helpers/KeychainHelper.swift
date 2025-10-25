//
//  KeychainHelper.swift
//  Optify
//
//  Created by Шоу on 6/21/25.
//

import Foundation
import CryptoKit

enum KeychainHelper {
    static func save(key: String, data: Data, accessible: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status), userInfo: nil)
        }
    }

    static func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(key: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key
        ]
        SecItemDelete(q as CFDictionary)
    }

    // String helpers.
    static func get(key: String) -> String? {
        guard let data = try? load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func set(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        try? save(key: key, data: data)
    }

    // UUID helpers (raw bytes).
    static func getUUID(key: String) -> UUID? {
        guard let data = try? load(key: key), data.count == MemoryLayout<uuid_t>.size else { return nil }
        return data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }

    static func setUUID(key: String, value: UUID) {
        var uuid = value.uuid
        let data = Data(bytes: &uuid, count: MemoryLayout<uuid_t>.size)
        try? save(key: key, data: data)
    }

    // Private key helpers.
    static func savePrivateKey(_ privateKey: Curve25519.KeyAgreement.PrivateKey, tag: String) throws {
        try save(key: tag, data: privateKey.rawRepresentation)
    }

    static func loadPrivateKey(tag: String) throws -> Curve25519.KeyAgreement.PrivateKey? {
        guard let data = try load(key: tag) else { return nil }
        return try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }
}
