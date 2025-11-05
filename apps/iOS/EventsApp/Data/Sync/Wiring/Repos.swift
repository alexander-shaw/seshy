//
//  Repos.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation
import CoreData

// MARK: Aggregator to be injected into tasks:
public struct Repos {
    public let publicProfileRepo: PublicProfileSyncRepository
    public let settingsRepo: UserSettingsSyncRepository
    public let loginRepo: UserLoginSyncRepository
    public let stack: CoreDataStack

    public init(publicProfileRepo: PublicProfileSyncRepository,
                settingsRepo: UserSettingsSyncRepository,
                loginRepo: UserLoginSyncRepository,
                stack: CoreDataStack
    ) {
        self.publicProfileRepo = publicProfileRepo
        self.settingsRepo = settingsRepo
        self.loginRepo = loginRepo
        self.stack = stack
    }

    public func withBackgroundContext(_ block: (NSManagedObjectContext) throws -> Void) throws {
        let ctx = stack.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        try block(ctx)
    }

    public func withBackgroundContext(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        try await stack.performBackgroundTask(block)
    }
}

// MARK: Sync-specific repository protocols (minimal interface for sync tasks):
public protocol PublicProfileSyncRepository {
    // Pull:
    func upsertPublicProfile(from dto: PublicProfileDTO, policy: ConflictRule, in ctx: NSManagedObjectContext) throws
    // Push:
    func pendingPublicProfileEdit() throws -> LocalPublicProfilePending?
    func markPublicProfileSynced(id: UUID, in ctx: NSManagedObjectContext) throws
}

public protocol UserSettingsSyncRepository {
    func upsertSettings(from dto: UserSettingsDTO, policy: ConflictRule, in ctx: NSManagedObjectContext) throws
    func pendingSettingsEdit() throws -> LocalSettingsPending?
    func markSettingsSynced(id: UUID, in ctx: NSManagedObjectContext) throws
}

public protocol UserLoginSyncRepository {
    func upsertLogin(from dto: UserLoginDTO, policy: ConflictRule, in ctx: NSManagedObjectContext) throws
    func pendingLoginEdit() throws -> LocalLoginPending?
    func markLoginSynced(id: UUID, in ctx: NSManagedObjectContext) throws
}

// MARK: Local pending view models the repos return for pushes:
public struct LocalPublicProfilePending {
    public let id: UUID
    public let idempotencyKey: String
}

public struct LocalSettingsPending {
    public let id: UUID
    public let idempotencyKey: String
}

public struct LocalLoginPending {
    public let id: UUID
    public let idempotencyKey: String
}
