//
//  PushPendingEditsTask.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation
import CoreData

public struct PushPendingEditsTask {
    let api: APIClient
    let repos: Repos
    let policy: SyncPolicy

    public init(api: APIClient, repos: Repos, policy: SyncPolicy) {
        self.api = api
        self.repos = repos
        self.policy = policy
    }

    public func run() async throws {
        // Pushes pending PublicProfile edit.
        if let pending = try repos.publicProfileRepo.pendingPublicProfileEdit() {
            // Gets the current PublicProfile DTO to create update DTO.
            let context = repos.stack.viewContext
            let profileRequest: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", pending.id as CVarArg)
            profileRequest.fetchLimit = 1
            
            if let profile = try context.fetch(profileRequest).first {
                let dto = mapPublicProfileToDTO(profile)
                let body = PublicProfileUpdateDTO.from(local: pending, dto: dto)
                let result: APIResult<PublicProfileDTO> = try await api.put("/me/public-profile", body: body, headers: ["Idempotency-Key": pending.idempotencyKey])

                if case .ok(_, _) = result.status {
                    try await repos.withBackgroundContext { ctx in
                        try repos.publicProfileRepo.markPublicProfileSynced(id: pending.id, in: ctx)
                        try ctx.saveIfNeeded()
                    }
                }
            }
        }

        // Pushes pending settings edit.
        if let pending = try repos.settingsRepo.pendingSettingsEdit() {
            // Gets the current settings DTO to create update DTO.
            let context = repos.stack.viewContext
            let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
            userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
            userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
            userRequest.fetchLimit = 1
            
            if let user = try context.fetch(userRequest).first,
               let settings = user.settings {
                let dto = mapUserSettingsToDTO(settings)
                let body = SettingsUpdateDTO.from(local: pending, dto: dto)
                let result: APIResult<UserSettingsDTO> = try await api.put("/me/settings", body: body, headers: ["Idempotency-Key": pending.idempotencyKey])

                if case .ok(_, _) = result.status {
                    try await repos.withBackgroundContext { ctx in
                        try repos.settingsRepo.markSettingsSynced(id: pending.id, in: ctx)
                        try ctx.saveIfNeeded()
                    }
                }
            }
        }

        // Pushes pending login edit (for contact matching - only hashed phone/email).
        if let pending = try repos.loginRepo.pendingLoginEdit() {
            // Gets the current login DTO - push full DTO for upsert (hashed phone/email for contact matching).
            let context = repos.stack.viewContext
            let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
            userRequest.predicate = NSPredicate(format: "login.lastLoginAt != nil")
            userRequest.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
            userRequest.fetchLimit = 1
            
            if let user = try context.fetch(userRequest).first,
               let login = user.login {
                let dto = mapUserLoginToDTO(login)
                // Pushes full UserLoginDTO for upsert - cloud uses hashed phone/email for contact matching.
                let result: APIResult<UserLoginDTO> = try await api.put("/me/login", body: dto, headers: ["Idempotency-Key": pending.idempotencyKey])

                if case .ok(_, _) = result.status {
                    try await repos.withBackgroundContext { ctx in
                        try repos.loginRepo.markLoginSynced(id: pending.id, in: ctx)
                        try ctx.saveIfNeeded()
                    }
                }
            }
        }
    }
}
