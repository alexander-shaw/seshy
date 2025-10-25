//
//  UserLoginRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain

protocol UserLoginRepository {
    func getCurrentUser() async throws -> DeviceUser?
    func setCurrentUser(_ user: DeviceUser) async throws
    func clearCurrentUser() async throws
    func findByPhoneNumber(_ phoneNumber: String) async throws -> DeviceUser?
    func createUserLogin(phoneNumber: String) async throws -> DeviceUser
    func updateLastLogin(for user: DeviceUser) async throws
    func verifyPhone(for user: DeviceUser) async throws
    func verifyEmail(for user: DeviceUser) async throws
}

final class CoreDataUserLoginRepository: UserLoginRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func getCurrentUser() async throws -> DeviceUser? {
        // Use main context for session management to avoid context sync issues.
        let context = coreDataStack.viewContext
        
        // Find the user with the most recent login.
        let request: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        request.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        request.fetchLimit = 1
        
        let users = try context.fetch(request)
        print("getCurrentUser: Found \(users.count) users with lastLoginAt")
        if let user = users.first {
            print("getCurrentUser: Current user ID: \(user.id), lastLoginAt: \(user.login?.lastLoginAt?.description ?? "nil")")
        }
        return users.first
    }
    
    func setCurrentUser(_ user: DeviceUser) async throws {
        // Use main context for session management to ensure consistency.
        let context = coreDataStack.viewContext
        
        // Get the user in this context using objectID.
        guard let contextUser = try context.existingObject(with: user.objectID) as? DeviceUser else {
            throw RepositoryError.userNotFound
        }
        
        // Update the login timestamp to mark this as the current user.
        contextUser.login?.lastLoginAt = Date()
        contextUser.login?.updatedAt = Date()
        contextUser.login?.syncStatus = .pending
        contextUser.updatedAt = Date()
        contextUser.syncStatus = .pending
        
        try context.save()
        print("setCurrentUser: Updated user \(contextUser.id) with lastLoginAt: \(contextUser.login?.lastLoginAt?.description ?? "nil")")
    }
    
    func clearCurrentUser() async throws {
        // Use main context for session management to ensure consistency.
        let context = coreDataStack.viewContext
        
        // Find the current user and clear their login timestamp.
        let request: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
        request.predicate = NSPredicate(format: "login.lastLoginAt != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "login.lastLoginAt", ascending: false)]
        request.fetchLimit = 1
        
        if let currentUser = try context.fetch(request).first {
            currentUser.login?.lastLoginAt = nil
            currentUser.login?.updatedAt = Date()
            currentUser.login?.syncStatus = .pending
            currentUser.updatedAt = Date()
            currentUser.syncStatus = .pending
            
            try context.save()
            print("clearCurrentUser: Cleared lastLoginAt for user \(currentUser.id)")
        }
    }
    
    func findByPhoneNumber(_ phoneNumber: String) async throws -> DeviceUser? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
            request.predicate = NSPredicate(format: "login.phoneE164Hashed == %@", phoneNumber)
            request.fetchLimit = 1
            
            let users = try context.fetch(request)
            return users.first
        }
    }
    
    func createUserLogin(phoneNumber: String) async throws -> DeviceUser {
        return try await coreDataStack.performBackgroundTask { context in
            let deviceUser = DeviceUser(context: context)
            deviceUser.id = UUID()
            deviceUser.createdAt = Date()
            deviceUser.updatedAt = Date()
            deviceUser.syncStatus = .pending
            
            let userLogin = UserLogin(context: context)
            userLogin.id = UUID()
            userLogin.createdAt = Date()
            userLogin.updatedAt = Date()
            userLogin.phoneE164Hashed = phoneNumber  // TODO: Implement hashing.
            userLogin.lastLoginAt = Date()
            userLogin.user = deviceUser
            userLogin.syncStatus = .pending
            
            deviceUser.login = userLogin
            
            try context.save()
            return deviceUser
        }
    }
    
    func updateLastLogin(for user: DeviceUser) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            user.login?.lastLoginAt = Date()
            user.login?.updatedAt = Date()
            user.login?.syncStatus = .pending
            user.updatedAt = Date()
            user.syncStatus = .pending
            try context.save()
        }
    }
    
    func verifyPhone(for user: DeviceUser) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            user.login?.phoneVerifiedAt = Date()
            user.login?.updatedAt = Date()
            user.login?.syncStatus = .pending
            try context.save()
        }
    }
    
    func verifyEmail(for user: DeviceUser) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            user.login?.emailVerifiedAt = Date()
            user.login?.updatedAt = Date()
            user.login?.syncStatus = .pending
            try context.save()
        }
    }
}
