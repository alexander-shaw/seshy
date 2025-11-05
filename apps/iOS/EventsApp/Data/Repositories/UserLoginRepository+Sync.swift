//
//  UserLoginRepository+Sync.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

// TODO: lastLoginAt and emailDomain should be synced.

import Foundation
import CoreData
import CoreDomain

// Purpose: Syncs UserLogin data for contact matching (hashed phone/email only).
// - Upserts hashed phone/email to cloud for contact matching.
// - Pulls hashed phone/email from cloud for contact matching.

extension CoreUserLoginRepository: UserLoginSyncRepository {
    func upsertLogin(from dto: UserLoginDTO, policy: ConflictRule, in ctx: NSManagedObjectContext) throws {
        // Finds the current user in the context.
        let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        userRequest.fetchLimit = 1
        
        guard let user = try ctx.fetch(userRequest).first else {
            throw RepositoryError.userNotFound
        }
        
        // Call the global upsertLogin function (not the method itself).
        // Use fully qualified name to avoid conflict with instance method.
        // TODO: try EventsApp.upsertLogin(from: dto, policy: policy, in: ctx, user: user)
    }
    
    func pendingLoginEdit() throws -> LocalLoginPending? {
        let context = coreDataStack.viewContext
        
        // Find current user.
        let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        userRequest.fetchLimit = 1
        
        guard let user = try context.fetch(userRequest).first,
              let login = user.login else {
            return nil
        }
        
        // Check if login has pending edits (needs sync for contact matching).
        // Sync when phone/email hashes change (for contact matching in cloud).
        guard login.syncStatus == SyncStatus.pending else {
            return nil
        }
        
        // Generate idempotency key (UUID string).
        let idempotencyKey = UUID().uuidString
        
        return LocalLoginPending(
            id: login.id,
            idempotencyKey: idempotencyKey
        )
    }
    
    func markLoginSynced(id: UUID, in ctx: NSManagedObjectContext) throws {
        let request: NSFetchRequest<UserLogin> = UserLogin.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        guard let login = try ctx.fetch(request).first else {
            return  // Not found, skip.
        }
        
        login.syncStatus = SyncStatus.synced
        login.lastCloudSyncedAt = Date()
    }
}
