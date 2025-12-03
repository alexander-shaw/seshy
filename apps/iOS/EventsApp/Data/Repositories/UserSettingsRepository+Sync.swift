//
//  UserSettingsRepository+Sync.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation
import CoreData

extension CoreUserSettingsRepository: UserSettingsSyncRepository {
    func upsertSettings(from dto: UserSettingsDTO, policy: ConflictRule, in ctx: NSManagedObjectContext) throws {
        // Finds the current user in the context.
        let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        userRequest.fetchLimit = 1
        
        guard let user = try ctx.fetch(userRequest).first else {
            throw RepositoryError.userNotFound
        }
        
        // TODO: try upsertSettings(from: dto, policy: policy, in: ctx, user: user)
    }
    
    func pendingSettingsEdit() throws -> LocalSettingsPending? {
        let context = coreDataStack.viewContext
        
        // Finds current user.
        let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        userRequest.fetchLimit = 1
        
        guard let user = try context.fetch(userRequest).first else {
            return nil
        }
        
        // Finds pending settings edit.
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        settingsRequest.predicate = NSPredicate(format: "user == %@ AND syncStatusRaw == %d", user, SyncStatus.pending.rawValue)
        settingsRequest.fetchLimit = 1
        
        guard let settings = try context.fetch(settingsRequest).first else {
            return nil
        }
        
        // Generates idempotency key (UUID string).
        let idempotencyKey = UUID().uuidString
        
        return LocalSettingsPending(
            id: settings.id,
            idempotencyKey: idempotencyKey
        )
    }
    
    func markSettingsSynced(id: UUID, in ctx: NSManagedObjectContext) throws {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        guard let settings = try ctx.fetch(request).first else {
            return  // Not found, skip.
        }
        
        settings.syncStatus = .synced
        settings.lastCloudSyncedAt = Date()
    }
}
