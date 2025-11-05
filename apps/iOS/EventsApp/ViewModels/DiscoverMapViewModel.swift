//
//  DiscoverMapViewModel.swift
//  EventsApp
//
//  Created on 10/25/25.
//

// TODO: Merge this code into UserSettingsViewModel.

import Foundation
import CoreLocation
import Combine
import CoreDomain
import CoreData
import MapboxMaps
import UIKit

@MainActor
final class DiscoverMapViewModel: ObservableObject {
    
    // MARK: Published State:
    @Published var center: CLLocationCoordinate2D
    @Published var zoom: Double
    @Published var bearing: Double
    // TODO: Add pitch and other attributes.

    @Published var endMode: EndMode = .all
    @Published var showingDatePicker = false
    
    // MARK: End Mode:
    enum EndMode: Hashable {
        case rollingDays(Int)
        case absolute(Date)
        case all
    }
    
    // MARK: Dependencies:
    private let repository: UserSettingsRepository
    private let themeManager: ThemeManager
    
    // MARK: Private State:
    private var cancellables = Set<AnyCancellable>()
    private var persistenceWorkItem: DispatchWorkItem?
    private let persistenceDelay: TimeInterval = 0.7
    
    // MARK: Computed Properties:
    var mapStyle: StyleURI {
        // TODO: Implement this.
        return .standard
    }
    
    // MARK: Initialization:
    init(
        repository: UserSettingsRepository = CoreUserSettingsRepository(),
        themeManager: ThemeManager? = nil,
        deviceUser: DeviceUser? = nil
    ) {
        self.repository = repository
        self.themeManager = themeManager ?? ThemeManager(initialTheme: .darkTheme)
        
        // Load last state:
        let (defaultCenter, defaultZoom, defaultBearing) = Self.defaultMapState()
        
        self.center = defaultCenter
        self.zoom = defaultZoom
        self.bearing = defaultBearing
        
        if let deviceUser = deviceUser {
            loadLastState(for: deviceUser)
        }
    }
    
    // MARK: Static Defaults:
    static func defaultMapState() -> (center: CLLocationCoordinate2D, zoom: Double, bearing: Double) {
        let center = CLLocationCoordinate2D(
            latitude: 46.7319,  // Washington State University.
            longitude: -117.1542
        )
        return (center, 15.0, 0.0)
    }
    
    // MARK: Public Intents:
    func onMapRegionChanged(center: CLLocationCoordinate2D, zoom: Double, bearing: Double) {
        self.center = center
        self.zoom = zoom
        self.bearing = bearing
        
        debouncedPersist()
        triggerLightHaptic()
    }
    
    func onDateButtonTap() {
        cycleDateMode()
        triggerLightHaptic()
    }
    
    func onDateButtonLongPress() {
        showingDatePicker = true
        triggerMediumHaptic()
    }
    
    func selectDate(_ date: Date) {
        endMode = .absolute(date)
        showingDatePicker = false
        persist()
    }
    
    // MARK: Private Methods:
    private func cycleDateMode() {
        switch endMode {
        case .all:
            endMode = .rollingDays(2)
        case .rollingDays(2):
            endMode = .rollingDays(14)  // 2 weeks.
        case .rollingDays(14):
            endMode = .rollingDays(30)  // 1 month.
        case .rollingDays(30):
            endMode = .rollingDays(180)  // 6 months.
        case .rollingDays(180):
            endMode = .all
        case .absolute:
            endMode = .all
        case .rollingDays(let days):
            // Handle any other rolling days values.
            switch days {
            case ...1:
                endMode = .rollingDays(2)
            case 3...13:
                endMode = .rollingDays(14)
            case 15...29:
                endMode = .rollingDays(30)
            case 31...179:
                endMode = .rollingDays(180)
            default:
                endMode = .all
            }
        }
        
        persist()
    }
    
    private func loadLastState(for deviceUser: DeviceUser) {
        Task {
            do {
                let context = CoreDataStack.shared.viewContext
                let settings = try repository.loadOrCreateSettings(for: deviceUser)
                
                await MainActor.run {
                    center = settings.mapCenterCoordinate
                    zoom = Double(settings.mapZoomLevel)
                    bearing = settings.mapBearingDegrees
                    
                    // Determine end mode.
                    if let endDate = settings.mapEndDate {
                        endMode = .absolute(endDate)
                    } else if let rollingDays = settings.mapEndRollingDays?.intValue {
                        endMode = .rollingDays(rollingDays)
                    } else {
                        endMode = .all
                    }
                }
            } catch {
                print("Failed to load map state:  \(error)")
            }
        }
    }
    
    private func persist() {
        guard let deviceUser = try? CoreDataStack.shared.viewContext.fetch(DeviceUser.fetchRequest()).first else {
            return
        }
        
        do {
            try repository.update { draft in
                draft.mapCenterLatitude = center.latitude
                draft.mapCenterLongitude = center.longitude
                draft.mapZoomLevel = Int16(zoom)
                draft.mapBearingDegrees = bearing

                switch endMode {
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
    
    private func debouncedPersist() {
        persistenceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.persist()
        }
        persistenceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + persistenceDelay, execute: workItem)
    }
    
    private func triggerLightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func triggerMediumHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: End Mode Description:
extension DiscoverMapViewModel.EndMode {
    var description: String {
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
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        case .all:
            return "All"
        }
    }
}
