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
import UIKit
import CoreLocation

@MainActor
public final class UserSettingsViewModel: ObservableObject {
    // MARK: Published State:
    @Published public var appearanceMode: AppearanceMode = .system  // Default to system
    @Published public var mapStyle: MapStyle = .darkMap
    @Published public var mapStartDate: Date?
    @Published public var mapMaxDistance: Double?  // Maximum distance in meters.  Nil means show all results worldwide.
    
    // Map state (merged from DiscoverMapViewModel):
    @Published public var mapCenter: CLLocationCoordinate2D
    @Published public var mapZoom: Double
    @Published public var mapBearing: Double
    @Published public var mapEndMode: MapEndMode = .all
    @Published public var showingDatePicker = false

    // MARK: Map End Mode:
    public enum MapEndMode: Hashable {
        case rollingDays(Int)
        case absolute(Date)
        case all
    }

    // MARK: Dependencies:
    private let repository: any UserSettingsRepository
    private let themeManager: ThemeManager
    
    // MARK: Private State:
    private var currentUserID: UUID?
    private var cancellables = Set<AnyCancellable>()
    private var persistenceWorkItem: DispatchWorkItem?
    private let persistenceDelay: TimeInterval = 0.7

    // MARK: Initialization:
    public init(
        repository: any UserSettingsRepository,
        themeManager: ThemeManager? = nil,
        deviceUser: DeviceUser? = nil
    ) {
        self.repository = repository
        self.themeManager = themeManager ?? ThemeManager()
        
        // Initialize map state with defaults
        let (defaultCenter, defaultZoom, defaultBearing) = Self.defaultMapState()
        self.mapCenter = defaultCenter
        self.mapZoom = defaultZoom
        self.mapBearing = defaultBearing
        
        // Subscribe to appearance mode changes to update theme.
        $appearanceMode
            .sink { [weak self] mode in
                self?.updateTheme(for: mode)
            }
            .store(in: &cancellables)
        
        // Initial theme update based on current appearance mode
        updateTheme(for: appearanceMode)
        
        // Load last state if device user is provided
        if let deviceUser = deviceUser {
            loadLastMapState(for: deviceUser)
        }
    }
    
    // MARK: Static Defaults:
    public static func defaultMapState() -> (center: CLLocationCoordinate2D, zoom: Double, bearing: Double) {
        let center = CLLocationCoordinate2D(
            latitude: 46.7319,  // Washington State University.
            longitude: -117.1542
        )
        return (center, 15.0, 0.0)
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
    
    // MARK: - MAP STATE METHODS (merged from DiscoverMapViewModel):
    public func onMapRegionChanged(center: CLLocationCoordinate2D, zoom: Double, bearing: Double) {
        self.mapCenter = center
        self.mapZoom = zoom
        self.mapBearing = bearing
        
        debouncedPersistMapState()
        triggerLightHaptic()
    }
    
    public func onDateButtonTap() {
        cycleDateMode()
        triggerLightHaptic()
    }
    
    public func onDateButtonLongPress() {
        showingDatePicker = true
        triggerMediumHaptic()
    }
    
    public func selectDate(_ date: Date) {
        mapEndMode = .absolute(date)
        showingDatePicker = false
        persistMapState()
    }
    
    // MARK: - PERSISTENCE:
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
                    mapCenterLatitude: mapCenter.latitude,
                    mapCenterLongitude: mapCenter.longitude,
                    mapZoomLevel: mapZoom,
                    mapStartDate: mapStartDate,
                    mapEndDate: mapEndDate,
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
    
    // Persist map state using repository's draft-based API
    private func persistMapState() {
        guard let deviceUser = try? CoreDataStack.shared.viewContext.fetch(DeviceUser.fetchRequest()).first else {
            return
        }
        
        do {
            try repository.update { draft in
                draft.mapCenterLatitude = mapCenter.latitude
                draft.mapCenterLongitude = mapCenter.longitude
                draft.mapZoomLevel = Int16(mapZoom)
                draft.mapBearingDegrees = mapBearing

                switch mapEndMode {
                    case .rollingDays(let days):
                        draft.mapEndRollingDays = NSNumber(value: days)
                        draft.mapEndDate = nil
                    case .absolute(let date):
                        draft.mapEndRollingDays = nil
                        draft.mapEndDate = date
                    case .all:
                        draft.mapEndRollingDays = nil
                        draft.mapEndDate = nil
                }
            }
        } catch {
            print("Failed to persist map state: \(error)")
        }
    }
    
    private func debouncedPersistMapState() {
        persistenceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.persistMapState()
        }
        persistenceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + persistenceDelay, execute: workItem)
    }
    
    private func loadLastMapState(for deviceUser: DeviceUser) {
        Task {
            do {
                let settings = try repository.loadOrCreateSettings(for: deviceUser)
                
                await MainActor.run {
                    mapCenter = settings.mapCenterCoordinate
                    mapZoom = Double(settings.mapZoomLevel)
                    mapBearing = settings.mapBearingDegrees
                    
                    // Determine end mode.
                    if let endDate = settings.mapEndDate {
                        mapEndMode = .absolute(endDate)
                    } else if let rollingDays = settings.mapEndRollingDays?.intValue {
                        mapEndMode = .rollingDays(rollingDays)
                    } else {
                        mapEndMode = .all
                    }
                }
            } catch {
                print("Failed to load map state:  \(error)")
            }
        }
    }
    
    private func cycleDateMode() {
        switch mapEndMode {
        case .all:
            mapEndMode = .rollingDays(2)
        case .rollingDays(2):
            mapEndMode = .rollingDays(14)  // 2 weeks.
        case .rollingDays(14):
            mapEndMode = .rollingDays(30)  // 1 month.
        case .rollingDays(30):
            mapEndMode = .rollingDays(180)  // 6 months.
        case .rollingDays(180):
            mapEndMode = .all
        case .absolute:
            mapEndMode = .all
        case .rollingDays(let days):
            // Handle any other rolling days values.
            switch days {
            case ...1:
                mapEndMode = .rollingDays(2)
            case 3...13:
                mapEndMode = .rollingDays(14)
            case 15...29:
                mapEndMode = .rollingDays(30)
            case 31...179:
                mapEndMode = .rollingDays(180)
            default:
                mapEndMode = .all
            }
        }
        
        persistMapState()
    }
    
    private func triggerLightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func triggerMediumHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Computed property for map end date
    private var mapEndDate: Date? {
        switch mapEndMode {
        case .absolute(let date):
            return date
        case .rollingDays(let days):
            return Calendar.current.date(byAdding: .day, value: days, to: Date())
        case .all:
            return nil
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
        switch mode {
        case .system:
            // Use system appearance
            themeManager.switchToSystemAppearance()
        case .darkMode:
            themeManager.switchToDark()
        case .lightMode:
            themeManager.switchToLight()
        }
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
        
        // Update map state from DTO
        mapCenter = CLLocationCoordinate2D(latitude: dto.mapCenterLatitude, longitude: dto.mapCenterLongitude)
        mapZoom = dto.mapZoomLevel
        // Note: mapBearing and mapEndMode need to be loaded from managed object, not DTO
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
        
        // Reset map state to defaults
        let (center, zoom, bearing) = Self.defaultMapState()
        mapCenter = center
        mapZoom = zoom
        mapBearing = bearing
        mapEndMode = .all
    }
}

// MARK: - Map End Mode Description:
extension UserSettingsViewModel.MapEndMode {
    public var description: String {
        switch self {
            case .rollingDays(let days):
                if days == 2 {
                    return "2d"
                } else if days == 14 {
                    return "2w"
                } else if days == 30 {
                    return "1m"
                } else if days == 180 {
                    return "6m"
                } else {
                    return "\(days)d"
                }
            case .absolute(let date):
                let formatter = Foundation.DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            case .all:
                return "All"
        }
    }
}
