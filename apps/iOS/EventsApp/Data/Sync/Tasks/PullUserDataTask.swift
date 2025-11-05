//
//  PullUserDataTask.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

public struct PullUserDataTask {
    let api: APIClient
    let repos: Repos
    let policy: SyncPolicy

    public init(api: APIClient, repos: Repos, policy: SyncPolicy) {
        self.api = api
        self.repos = repos
        self.policy = policy
    }

    // Pull PublicProfile data.
    // Returns a new ETag if server responded 200 - or nil if 304.
    public func pullPublicProfile(etag: String?) async throws -> String? {
        let headers = etag.map { ["If-None-Match": $0] } ?? [:]
        
        let result: APIResult<PublicProfileDTO> = try await api.get("/me/public-profile", headers: headers)
        switch result.status {
        case .notModified:
            return nil
        case .ok(let dto, let newTag):
            try await repos.withBackgroundContext { ctx in
                try repos.publicProfileRepo.upsertPublicProfile(from: dto, policy: policy.publicProfile, in: ctx)
                try ctx.saveIfNeeded()
            }
            return newTag
        }
    }

    // Pull settings data.
    // Returns a new ETag if server responded 200 - or nil if 304.
    public func pullSettings(etag: String?) async throws -> String? {
        let headers = etag.map { ["If-None-Match": $0] } ?? [:]
        
        let result: APIResult<UserSettingsDTO> = try await api.get("/me/settings", headers: headers)
        switch result.status {
        case .notModified:
            return nil
        case .ok(let dto, let newTag):
            try await repos.withBackgroundContext { ctx in
                try repos.settingsRepo.upsertSettings(from: dto, policy: policy.settings, in: ctx)
                try ctx.saveIfNeeded()
            }
            return newTag
        }
    }

    // Pulls login data.
    // Returns a new ETag if server responded 200 - or nil if 304.
    public func pullLogin(etag: String?) async throws -> String? {
        let headers = etag.map { ["If-None-Match": $0] } ?? [:]
        
        let result: APIResult<UserLoginDTO> = try await api.get("/me/login", headers: headers)
        switch result.status {
        case .notModified:
            return nil
        case .ok(let dto, let newTag):
            try await repos.withBackgroundContext { ctx in
                try repos.loginRepo.upsertLogin(from: dto, policy: .serverWins, in: ctx)
                try ctx.saveIfNeeded()
            }
            return newTag
        }
    }
}
