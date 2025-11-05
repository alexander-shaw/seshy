//
//  PublicProfileRepository+Sync.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation
import CoreData
import CoreDomain

extension CorePublicProfileRepository: PublicProfileSyncRepository {
    func upsertPublicProfile(from dto: PublicProfileDTO, policy: ConflictRule, in ctx: NSManagedObjectContext) throws {
        // Finds the current user in the context.
        let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        userRequest.fetchLimit = 1
        
        guard let user = try ctx.fetch(userRequest).first else {
            throw RepositoryError.userNotFound
        }
        
        // TODO: try upsertPublicProfile(from: dto, policy: policy, in: ctx, user: user)
    }
    
    func pendingPublicProfileEdit() throws -> LocalPublicProfilePending? {
        let context = coreDataStack.viewContext
        
        // Finds pending PublicProfile edit.
        let profileRequest: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
        profileRequest.predicate = NSPredicate(format: "syncStatusRaw == %d", SyncStatus.pending.rawValue)
        profileRequest.fetchLimit = 1
        
        guard let profile = try context.fetch(profileRequest).first else {
            return nil
        }
        
        // Generates idempotency key (UUID string).
        let idempotencyKey = UUID().uuidString
        
        return LocalPublicProfilePending(
            id: profile.id,
            idempotencyKey: idempotencyKey
        )
    }
    
    func markPublicProfileSynced(id: UUID, in ctx: NSManagedObjectContext) throws {
        let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        guard let profile = try ctx.fetch(request).first else {
            return  // Not found, skip.
        }
        
        profile.syncStatus = .synced
        profile.lastCloudSyncedAt = Date()
    }
}
