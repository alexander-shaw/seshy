//
//  SystemVibeHydrator.swift
//  EventsApp
//
//  Created by Шоу on 11/19/25.
//

import Foundation
import CoreData

struct SystemVibeHydrator {
    private enum Keys {
        static let etag = "systemVibes.etag"
        static let lastSync = "systemVibes.lastSync"
    }

    private let api: APIClient
    private let stack: CoreDataStack
    private let defaults: UserDefaults

    init(
        api: APIClient = HTTPAPIClient(),
        stack: CoreDataStack = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.api = api
        self.stack = stack
        self.defaults = defaults
    }

    var lastSyncDate: Date? {
        defaults.object(forKey: Keys.lastSync) as? Date
    }

    @MainActor
    func refresh(statusHandler: ((String) -> Void)? = nil) async throws {
        let headers: [String: String]
        if let etag = defaults.string(forKey: Keys.etag) {
            headers = ["If-None-Match": etag]
        } else {
            headers = [:]
        }

        statusHandler?("Checking vibes…")
        let result: APIResult<[VibeDTO]> = try await api.get(
            "/vibes?system_only=true&active_only=true",
            headers: headers
        )

        switch result.status {
        case .notModified:
            statusHandler?("System vibes are current.")
            return
        case .ok(let payload, let newEtag):
            statusHandler?("Applying \(payload.count) system vibes…")
            try await stack.performBackgroundTask { ctx in
                try upsertSystemVibes(payload, in: ctx)
                try ctx.saveIfNeeded()
            }

            if let etag = newEtag {
                defaults.set(etag, forKey: Keys.etag)
            }
            defaults.set(Date(), forKey: Keys.lastSync)
            statusHandler?("System vibes refreshed.")
        }
    }

    private func upsertSystemVibes(_ payload: [VibeDTO], in ctx: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
        request.predicate = NSPredicate(format: "systemDefined == YES")
        let existing = try ctx.fetch(request)
        var existingBySlug = Dictionary(uniqueKeysWithValues: existing.map { ($0.slug, $0) })

        for dto in payload {
            if let current = existingBySlug.removeValue(forKey: dto.slug) {
                current.apply(dto)
                current.systemDefined = true
                current.syncStatus = .synced
            } else {
                let vibe = Vibe.insert(into: ctx, from: dto)
                vibe.systemDefined = true
                vibe.syncStatus = .synced
            }
        }

        // Any system vibe not returned by the server should be hidden but kept locally.
        for leftover in existingBySlug.values {
            leftover.isActive = false
            leftover.updatedAt = Date()
            leftover.syncStatus = .synced
        }
    }
}

