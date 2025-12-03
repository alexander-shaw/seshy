//
//  UserSettingsRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreLocation

public protocol UserSettingsRepository: Sendable {
    // Load or create settings for a device user.
    func loadOrCreateSettings(for deviceUser: DeviceUser) throws -> UserSettings
    
    // Stage changes in a draft and apply in one save operation.
    func update(_ mutate: (inout UserSettingsDraft) -> Void) throws
    
    // DTO-based methods for compatibility.
    func getSettings(for userID: UUID) async throws -> UserSettingsDTO?
    func getSettings(for user: DeviceUser) async throws -> UserSettingsDTO?
    func updateSettings(_ settingsDTO: UserSettingsDTO) async throws -> UserSettingsDTO?
    func createSettings(for userID: UUID) async throws -> UserSettingsDTO
    func createSettings(for user: DeviceUser) async throws -> UserSettingsDTO
}

final class CoreUserSettingsRepository: UserSettingsRepository {
    let coreDataStack: CoreDataStack
    private let viewContext: NSManagedObjectContext
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        self.viewContext = coreDataStack.viewContext
    }
    
    // MARK: - DRAFT-BASED API:
    func loadOrCreateSettings(for deviceUser: DeviceUser) throws -> UserSettings {
        let fetchRequest = UserSettings.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user == %@", deviceUser)
        fetchRequest.fetchLimit = 1
        
        if let existing = try viewContext.fetch(fetchRequest).first {
            return existing
        }
        
        // Create new settings with sensible defaults.
        let newSettings = UserSettings(context: viewContext)
        newSettings.id = UUID()
        newSettings.createdAt = Date()
        newSettings.updatedAt = Date()
        newSettings.appearanceModeRaw = AppearanceMode.system.rawValue  // Default to system
        newSettings.mapStyleRaw = MapStyle.darkMap.rawValue
        newSettings.mapCenterLatitude = 46.7319  // Washington State University default.
        newSettings.mapCenterLongitude = -117.1542
        newSettings.mapZoomLevel = 15  // City-level zoom.
        newSettings.mapBearingDegrees = 0
        newSettings.mapPitchDegrees = 0
        newSettings.mapStartDate = nil  // Nil is now. If start < now, then set to nil.
        newSettings.mapEndRollingDays = nil  // nil = All
        newSettings.mapMaxDistance = nil  // Nil means show all results worldwide.
        newSettings.syncStatusRaw = SyncStatus.pending.rawValue
        
        deviceUser.settings = newSettings
        
        try viewContext.save()
        return newSettings
    }
    
    func update(_ mutate: (inout UserSettingsDraft) -> Void) throws {
        let fetchRequest = UserSettings.fetchRequest()
        
        guard let settings = try viewContext.fetch(fetchRequest).first else {
            throw RepositoryError.userNotFound
        }
        
        var draft = UserSettingsDraft(from: settings)
        mutate(&draft)
        draft.apply(to: settings)
        
        try viewContext.save()
    }
    
    // MARK: - DTO-BASED API:
    func getSettings(for user: DeviceUser) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            guard let contextUser = try context.existingObject(with: user.objectID) as? DeviceUser else {
                return nil
            }
            
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "user == %@", contextUser)
            request.fetchLimit = 1
            
            let settings = try context.fetch(request)
            return settings.first.map(mapUserSettingsToDTO)
        }
    }
    
    func createSettings(for user: DeviceUser) async throws -> UserSettingsDTO {
        return try await coreDataStack.performBackgroundTask { context in
            guard let contextUser = try context.existingObject(with: user.objectID) as? DeviceUser else {
                throw RepositoryError.userNotFound
            }
            
            let settings = UserSettings(context: context)
            settings.id = UUID()
            settings.createdAt = Date()
            settings.updatedAt = Date()
            settings.appearanceModeRaw = AppearanceMode.system.rawValue
            settings.mapStyleRaw = MapStyle.darkMap.rawValue
            settings.mapCenterLatitude = 46.7319
            settings.mapCenterLongitude = -117.1542
            settings.mapZoomLevel = 15
            settings.mapBearingDegrees = 0
            settings.mapPitchDegrees = 0
            settings.mapStartDate = nil  // Nil is now. If start < now, then set to nil.
            settings.mapEndRollingDays = nil
            settings.mapMaxDistance = nil  // Nil means show all results worldwide.
            settings.user = contextUser
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            contextUser.settings = settings
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func getSettings(for userID: UUID) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "user.id == %@", userID as CVarArg)
            request.fetchLimit = 1
            
            let settings = try context.fetch(request)
            return settings.first.map(mapUserSettingsToDTO)
        }
    }
    
    func updateSettings(_ settingsDTO: UserSettingsDTO) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsDTO.id as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.apply(settingsDTO)
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func createSettings(for userID: UUID) async throws -> UserSettingsDTO {
        return try await coreDataStack.performBackgroundTask { context in
            let userRequest: NSFetchRequest<DeviceUser> = DeviceUser.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userID as CVarArg)
            userRequest.fetchLimit = 1
            
            guard let user = try context.fetch(userRequest).first else {
                throw RepositoryError.userNotFound
            }
            
            let settings = UserSettings(context: context)
            settings.id = UUID()
            settings.createdAt = Date()
            settings.updatedAt = Date()
            settings.appearanceModeRaw = AppearanceMode.system.rawValue
            settings.mapStyleRaw = MapStyle.darkMap.rawValue
            settings.mapCenterLatitude = 46.7319
            settings.mapCenterLongitude = -117.1542
            settings.mapZoomLevel = 15
            settings.mapBearingDegrees = 0
            settings.mapPitchDegrees = 0
            settings.mapStartDate = nil  // Nil is now. If start < now, then set to nil.
            settings.mapEndRollingDays = nil
            settings.mapMaxDistance = nil  // Nil means show all results worldwide.
            settings.user = user
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            user.settings = settings
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
}
