//
//  PublicProfileRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

public protocol PublicProfileRepository: Sendable {
    func createPublicProfile(id: UUID, displayName: String, username: String?, avatarURL: String?, bio: String?, ageYears: Int?, gender: String?, isVerified: Bool) async throws -> PublicProfile
    func getPublicProfile(by id: UUID) async throws -> PublicProfile?
    func getPublicProfile(by username: String) async throws -> PublicProfile?
    func getAllPublicProfiles() async throws -> [PublicProfile]
    func searchPublicProfiles(query: String) async throws -> [PublicProfile]
    func updatePublicProfile(_ profileDTO: PublicProfile) async throws -> PublicProfile?
    func deletePublicProfile(_ profileID: UUID) async throws
    func getVerifiedProfiles() async throws -> [PublicProfile]
    func getProfilesByAgeRange(minAge: Int, maxAge: Int) async throws -> [PublicProfile]
    func refreshPublicProfile(_ profileID: UUID) async throws -> PublicProfile?
    func cleanupOldProfiles(olderThan date: Date) async throws -> Int
}

final class CorePublicProfileRepository: PublicProfileRepository {
    let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func createPublicProfile(id: UUID, displayName: String, username: String? = nil, avatarURL: String? = nil, bio: String? = nil, ageYears: Int? = nil, gender: String? = nil, isVerified: Bool = false) async throws -> PublicProfile {
        return try await coreDataStack.performBackgroundTask { context in
            let profile = PublicProfile(context: context)
            profile.id = id
            profile.createdAt = Date()
            profile.updatedAt = Date()
            profile.displayName = displayName
            profile.username = username
            profile.avatarURL = avatarURL
            profile.bio = bio
            profile.ageYears = ageYears.map { NSNumber(value: $0) }
            profile.gender = gender
            profile.isVerified = isVerified
            profile.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return profile
        }
    }
    
    func getPublicProfile(by id: UUID) async throws -> PublicProfile? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            let profiles = try context.fetch(request)
            return profiles.first
        }
    }
    
    func getPublicProfile(by username: String) async throws -> PublicProfile? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", username)
            request.fetchLimit = 1
            
            let profiles = try context.fetch(request)
            return profiles.first
        }
    }
    
    func getAllPublicProfiles() async throws -> [PublicProfile] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PublicProfile.displayName, ascending: true)]
            
            let profiles = try context.fetch(request)
            return profiles
        }
    }
    
    func searchPublicProfiles(query: String) async throws -> [PublicProfile] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "displayName CONTAINS[cd] %@ OR username CONTAINS[cd] %@ OR bio CONTAINS[cd] %@", 
                                          query, query, query)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PublicProfile.displayName, ascending: true)]
            
            let profiles = try context.fetch(request)
            return profiles
        }
    }
    
    func updatePublicProfile(_ profile: PublicProfile) async throws -> PublicProfile? {
        return try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            profile.updatedAt = Date()
            profile.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return profile
        }
    }
    
    func deletePublicProfile(_ profileID: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", profileID as CVarArg)
            request.fetchLimit = 1
            
            if let profile = try context.fetch(request).first {
                context.delete(profile)
                try context.save()
            }
        }
    }
    
    func getVerifiedProfiles() async throws -> [PublicProfile] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "isVerified == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PublicProfile.displayName, ascending: true)]
            
            let profiles = try context.fetch(request)
            return profiles
        }
    }
    
    func getProfilesByAgeRange(minAge: Int, maxAge: Int) async throws -> [PublicProfile] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "ageYears >= %d AND ageYears <= %d", minAge, maxAge)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PublicProfile.displayName, ascending: true)]
            
            let profiles = try context.fetch(request)
            return profiles
        }
    }
    
    func refreshPublicProfile(_ profileID: UUID) async throws -> PublicProfile? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", profileID as CVarArg)
            request.fetchLimit = 1
            
            guard let profile = try context.fetch(request).first else { return nil }
            
            // Mark for refresh from server.
            profile.syncStatusRaw = SyncStatus.pending.rawValue
            profile.updatedAt = Date()
            
            try context.save()
            return profile
        }
    }
    
    func cleanupOldProfiles(olderThan date: Date) async throws -> Int {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
            request.predicate = NSPredicate(format: "updatedAt < %@", date as NSDate)
            
            let oldProfiles = try context.fetch(request)
            let count = oldProfiles.count
            
            for profile in oldProfiles {
                context.delete(profile)
            }
            
            try context.save()
            return count
        }
    }
}
