//
//  UserSettingsViewModel.swift
//  EventsApp
//
//  Created on 10/25/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain
import UIKit

/// Manages user preferences and settings including appearance mode, map style, and units.
/// Provides a reactive interface for SwiftUI views to observe and modify user settings.
@MainActor
public final class UserSettingsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var appearanceMode: AppearanceMode = .system
    @Published public var mapStyle: MapStyle = .darkMap
    @Published public var preferredUnits: Units = .imperial
    
    // MARK: - Computed Properties
    
    /// System measurement default based on locale
    public var systemMeasurementDefault: Units {
        Locale.current.usesMetricSystem ? .metric : .imperial
    }
    
    /// Active theme resolved from ThemeViewModel
    public var activeTheme: AppTheme {
        let themeViewModel = ThemeViewModel()
        let systemStyle = UITraitCollection.current.userInterfaceStyle
        let (theme, _) = themeViewModel.resolvedAppearance(
            systemStyle: systemStyle,
            userMode: appearanceMode,
            now: Date()
        )
        return theme
    }
    
    /// Effective units to use (preferred or system default)
    public var effectiveUnits: Units {
        preferredUnits
    }
    
    // MARK: - Dependencies
    
    private let repository: any UserSettingsRepository
    private let themeManager: ThemeManager
    
    // MARK: - Private State
    
    private var currentUserID: UUID?
    private var cancellables = Set<AnyCancellable>()
    
    // Debounce timer for persistence
    private var persistenceWorkItem: DispatchWorkItem?
    private let persistenceDelay: TimeInterval = 0.5
    
    // MARK: - Initialization
    
    public init(
        repository: any UserSettingsRepository,
        themeManager: ThemeManager? = nil
    ) {
        self.repository = repository
        self.themeManager = themeManager ?? ThemeManager(initialTheme: .darkTheme)
        
        // Subscribe to appearance mode changes to update theme
        $appearanceMode
            .sink { [weak self] mode in
                self?.updateTheme(for: mode)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Intents
    
    /// Select an appearance mode
    /// - Parameter mode: The appearance mode to set
    public func selectAppearanceMode(_ mode: AppearanceMode) {
        guard appearanceMode != mode else { return }
        appearanceMode = mode
        debouncedPersist()
    }
    
    /// Select preferred units
    /// - Parameter units: The units to use (nil defaults to system measurement)
    public func selectUnits(_ units: Units?) {
        let targetUnits = units ?? systemMeasurementDefault
        guard preferredUnits != targetUnits else { return }
        preferredUnits = targetUnits
        debouncedPersist()
    }
    
    /// Select map style
    /// - Parameter style: The map style to use
    public func selectMapStyle(_ style: MapStyle) {
        guard mapStyle != style else { return }
        mapStyle = style
        debouncedPersist()
    }
    
    /// Load settings from repository
    public func refreshFromStore() async {
        guard let userID = currentUserID else { return }
        
        do {
            if let settingsDTO = try await repository.getSettings(for: userID) {
                await MainActor.run {
                    updateFromDTO(settingsDTO)
                }
            }
            else {
                // Create default settings if none exist
                let createdDTO = try await repository.createSettings(for: userID)
                await MainActor.run {
                    updateFromDTO(createdDTO)
                }
            }
        } catch {
            print("Failed to refresh settings: \(error)")
        }
    }
    
    /// Manually persist settings to Core Data
    public func persist() {
        guard let userID = currentUserID else { return }
        
        Task {
            do {
                // Create DTO with proper structure
                let dto = UserSettingsDTO(
                    id: UUID(), // Will be replaced by repository if updating existing
                    appearanceModeRaw: appearanceMode.rawValue,
                    unitsRaw: preferredUnits.rawValue,
                    mapStyleRaw: mapStyle.rawValue,
                    mapCenterLatitude: 0,
                    mapCenterLongitude: 0,
                    mapZoomLevel: 0,
                    mapEndDate: nil,
                    mapMaxDistance: nil,
                    updatedAt: Date(),
                    schemaVersion: 1
                )
                
                _ = try await repository.updateSettings(dto)
            } catch {
                print("Failed to persist settings: \(error)")
            }
        }
    }
    
    /// Set the current user ID (typically called on login)
    public func setUserID(_ userID: UUID) {
        currentUserID = userID
        Task {
            await refreshFromStore()
        }
    }
    
    // MARK: - Private Methods
    
    /// Update theme based on appearance mode
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
    
    /// Update local state from DTO
    private func updateFromDTO(_ dto: UserSettingsDTO) {
        appearanceMode = AppearanceMode(rawValue: dto.appearanceModeRaw) ?? .system
        mapStyle = MapStyle(rawValue: dto.mapStyleRaw) ?? .darkMap
        preferredUnits = Units(rawValue: dto.unitsRaw) ?? (Locale.current.usesMetricSystem ? .metric : .imperial)
    }
    
    /// Debounced persistence to prevent excessive Core Data writes
    private func debouncedPersist() {
        // Cancel any pending persistence
        persistenceWorkItem?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem { [weak self] in
            self?.persist()
        }
        persistenceWorkItem = workItem
        
        // Schedule after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + persistenceDelay, execute: workItem)
    }
}

// MARK: - Convenience Extensions

extension UserSettingsViewModel {
    /// Toggle between light and dark mode (only if not in system mode)
    public func toggleDarkMode() {
        switch appearanceMode {
        case .system:
            // Can't toggle when in system mode
            break
        case .darkMode:
            selectAppearanceMode(.lightMode)
        case .lightMode:
            selectAppearanceMode(.darkMode)
        }
    }
    
    /// Reset to system defaults
    public func resetToDefaults() {
        selectAppearanceMode(.system)
        selectUnits(systemMeasurementDefault)
        selectMapStyle(.darkMap)
    }
}
