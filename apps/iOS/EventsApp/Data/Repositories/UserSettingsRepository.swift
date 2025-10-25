//
//  UserSettingsRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import CoreDomain
import CoreLocation

public protocol UserSettingsRepository: Sendable {
    func getSettings(for userID: UUID) async throws -> UserSettingsDTO?
    func getSettings(for user: DeviceUser) async throws -> UserSettingsDTO?
    func updateSettings(_ settingsDTO: UserSettingsDTO) async throws -> UserSettingsDTO?
    func createSettings(for userID: UUID) async throws -> UserSettingsDTO
    func createSettings(for user: DeviceUser) async throws -> UserSettingsDTO
    func updateAppearanceMode(_ settingsID: UUID, mode: AppearanceMode) async throws -> UserSettingsDTO?
    func updateMapStyle(_ settingsID: UUID, style: MapStyle) async throws -> UserSettingsDTO?
    func updatePreferredUnits(_ settingsID: UUID, units: Units) async throws -> UserSettingsDTO?
    
    // Map preference methods.
    func updateMapCenter(_ settingsID: UUID, coordinate: CLLocationCoordinate2D) async throws -> UserSettingsDTO?
    func updateMapZoom(_ settingsID: UUID, zoomLevel: Double) async throws -> UserSettingsDTO?
    func updateMapEndDate(_ settingsID: UUID, endDate: Date?) async throws -> UserSettingsDTO?
    func updateMapMaxDistance(_ settingsID: UUID, maxDistance: Double?) async throws -> UserSettingsDTO?
    func updatePreferredTags(_ settingsID: UUID, tags: Set<Tag>) async throws -> UserSettingsDTO?
}

final class CoreDataUserSettingsRepository: UserSettingsRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func getSettings(for user: DeviceUser) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            // Use objectID to fetch the user in this context.
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
            // Use objectID to fetch the user in this context.
            guard let contextUser = try context.existingObject(with: user.objectID) as? DeviceUser else {
                throw RepositoryError.userNotFound
            }
            
            let settings = UserSettings(context: context)
            settings.id = UUID()
            settings.createdAt = Date()
            settings.updatedAt = Date()
            settings.appearanceModeRaw = AppearanceMode.system.rawValue
            settings.mapStyleRaw = MapStyle.darkMap.rawValue
            settings.preferredUnitsRaw = Units.imperial.rawValue
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
            // First fetch the user.
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
            settings.preferredUnitsRaw = Units.imperial.rawValue
            settings.user = user
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            user.settings = settings
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updateAppearanceMode(_ settingsID: UUID, mode: AppearanceMode) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.appearanceModeRaw = mode.rawValue
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updateMapStyle(_ settingsID: UUID, style: MapStyle) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.mapStyleRaw = style.rawValue
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updatePreferredUnits(_ settingsID: UUID, units: Units) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.preferredUnitsRaw = units.rawValue
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updateMapCenter(_ settingsID: UUID, coordinate: CLLocationCoordinate2D) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.mapCenterLatitude = coordinate.latitude
            settings.mapCenterLongitude = coordinate.longitude
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updateMapZoom(_ settingsID: UUID, zoomLevel: Double) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.mapZoomLevel = Int16(zoomLevel)
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updateMapEndDate(_ settingsID: UUID, endDate: Date?) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            settings.mapEndDate = endDate
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updateMapMaxDistance(_ settingsID: UUID, maxDistance: Double?) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            // TODO: mapMaxDistance is not stored in the Core Data model yet.
            // This method is included for protocol conformance but doesn't persist the value
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
    
    func updatePreferredTags(_ settingsID: UUID, tags: Set<Tag>) async throws -> UserSettingsDTO? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", settingsID as CVarArg)
            request.fetchLimit = 1
            
            guard let settings = try context.fetch(request).first else { return nil }
            
            // TODO: preferredTags relationship is not implemented in the Core Data model yet
            // This method is included for protocol conformance but doesn't persist the tags
            settings.updatedAt = Date()
            settings.syncStatusRaw = SyncStatus.pending.rawValue
            
            try context.save()
            return mapUserSettingsToDTO(settings)
        }
    }
}
