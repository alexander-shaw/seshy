//
//  UserSettingsViewModel.swift
//  EventsApp
//
//  Created on 10/25/25.
//

// Manages user preferences and settings including appearance mode and map style.
// Provides a reactive interface for SwiftUI views to observe and modify user settings.

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain
import UIKit

@MainActor
public final class UserSettingsViewModel: ObservableObject {
    // MARK: Published State:
    @Published public var appearanceMode: AppearanceMode = .system
    @Published public var mapStyle: MapStyle = .darkMap
    @Published public var mapStartDate: Date?
    @Published public var mapMaxDistance: Double?  // Maximum distance in meters.  Nil means show all results worldwide.

    // MARK: Dependencies:
    private let repository: any UserSettingsRepository
    private let themeManager: ThemeManager
    
    // MARK: Private State:
    private var currentUserID: UUID?
    private var cancellables = Set<AnyCancellable>()

    // MARK: Initialization:
    public init(
        repository: any UserSettingsRepository,
        themeManager: ThemeManager? = nil
    ) {
        self.repository = repository
        self.themeManager = themeManager ?? ThemeManager(initialTheme: .darkTheme)
        
        // Subscribe to appearance mode changes to update theme.
        $appearanceMode
            .sink { [weak self] mode in
                self?.updateTheme(for: mode)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - PUBLIC INTENTS:
    // Select an appearance mode.
    public func selectAppearanceMode(_ mode: AppearanceMode) {
        guard appearanceMode != mode else { return }
        appearanceMode = mode
    }
    
    // Select map style.
    public func selectMapStyle(_ style: MapStyle) {
        guard mapStyle != style else { return }
        mapStyle = style
    }
    
    // Select map start date for filtering (nil means now).
    public func selectMapStartDate(_ date: Date?) {
        // If start < now, then set to nil per UserSettings comment.
        if let date = date, date < Date() {
            mapStartDate = nil
        } else {
            mapStartDate = date
        }
    }
    
    // Select maximum distance filter (nil means show all worldwide).
    public func selectMapMaxDistance(_ distance: Double?) {
        guard mapMaxDistance != distance else { return }
        mapMaxDistance = distance
    }
    
    // Load settings from repository.
    public func refreshFromStore() async {
        guard let userID = currentUserID else { return }
        
        do {
            if let settingsDTO = try await repository.getSettings(for: userID) {
                await MainActor.run {
                    updateFromDTO(settingsDTO)
                }
            }
            else {
                // Create default settings if none exist.
                let createdDTO = try await repository.createSettings(for: userID)
                await MainActor.run {
                    updateFromDTO(createdDTO)
                }
            }
        } catch {
            print("Failed to refresh settings:  \(error)")
        }
    }
    
    // Manually persist settings to Core Data.
    public func persist() {
        guard let userID = currentUserID else { return }
        
        Task {
            do {
                // Create DTO with proper structure.
                let dto = UserSettingsDTO(
                    id: UUID(),  // Will be replaced by repository if updating existing.
                    appearanceModeRaw: appearanceMode.rawValue,
                    mapStyleRaw: mapStyle.rawValue,
                    mapCenterLatitude: 0,
                    mapCenterLongitude: 0,
                    mapZoomLevel: 0,
                    mapStartDate: mapStartDate,
                    mapEndDate: nil,
                    mapMaxDistance: mapMaxDistance,
                    updatedAt: Date(),
                    schemaVersion: 1
                )
                
                _ = try await repository.updateSettings(dto)
            } catch {
                print("Failed to persist settings:  \(error)")
            }
        }
    }
    
    // Set the current user ID (typically called on login).
    public func setUserID(_ userID: UUID) {
        currentUserID = userID
        Task {
            await refreshFromStore()
        }
    }
    
    // MARK: - PRIVATE METHODS:
    // Update theme based on appearance mode.
    private func updateTheme(for mode: AppearanceMode) {
        let systemStyle: UIUserInterfaceStyle
        
        switch mode {
        case .system:
            systemStyle = UITraitCollection.current.userInterfaceStyle
        case .darkMode:
            systemStyle = .dark
        case .lightMode:
            systemStyle = .light
        }
        
        let theme = systemStyle == .dark ? AppTheme.darkTheme : AppTheme.lightTheme
        themeManager.currentTheme = theme
    }
    
    // Update local state from DTO.
    private func updateFromDTO(_ dto: UserSettingsDTO) {
        appearanceMode = AppearanceMode(rawValue: dto.appearanceModeRaw) ?? .system
        mapStyle = MapStyle(rawValue: dto.mapStyleRaw) ?? .darkMap
        // If start < now, then set to nil per UserSettings comment.
        if let startDate = dto.mapStartDate, startDate < Date() {
            mapStartDate = nil
        } else {
            mapStartDate = dto.mapStartDate
        }
        mapMaxDistance = dto.mapMaxDistance
    }
}

// MARK: - CONVENIENCE METHODS:
extension UserSettingsViewModel {
    // Reset to system defaults.
    public func resetToDefaults() {
        selectAppearanceMode(.system)
        selectMapStyle(.darkMap)
        selectMapStartDate(nil)
        selectMapMaxDistance(nil)
    }
}
