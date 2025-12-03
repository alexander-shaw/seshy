//
//  LocationViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//
//  Inspired by the Optify implementation.  This version focuses on
//  dynamically monitoring Apple event regions (CLCircularRegion) for the
//  next <20 upcoming events.  Location data is only captured while the user
//  is actively using the app and has opted in.
//

import Combine
import CoreData
import CoreLocation
import Foundation
import SwiftUI
import UIKit

@MainActor
final class LocationViewModel: NSObject, ObservableObject {
    static let shared = LocationViewModel()
    
    enum RegionEvent: String {
        case entered
        case exited
    }
    
    // MARK: Published State
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var trackingPreferenceEnabled: Bool = false
    @Published private(set) var isMonitoringEventRegions: Bool = false
    @Published private(set) var monitoredRegionCount: Int = 0
    @Published private(set) var lastKnownLocation: CLLocation?
    @Published private(set) var lastRegionIdentifier: String?
    @Published private(set) var lastRegionEvent: RegionEvent?
    @Published private(set) var errorMessage: String?
    @Published private(set) var permissionDenied: Bool = false
    
    // MARK: Location Onboarding State
    enum LocationStep {
        case permission
        case manual
    }
    
    @Published var currentStep: LocationStep = .permission
    @Published var isSavingManualLocation = false
    @Published var manualLocationErrorMessage: String?
    
    // MARK: Private State
    private let locationManager: CLLocationManager
    private let coreDataStack: CoreDataStack
    private let userProfileRepository: UserProfileRepository = CoreUserProfileRepository()
    private var isPreferenceEnabled: Bool = false
    private var regionRefreshTask: Task<Void, Never>?
    private var managedObjectObserver: NSObjectProtocol?
    private weak var userSession: UserSessionViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    private let maxRegions = 20
    private let minRegionRadius: CLLocationDistance = 25
    private let maxRegionRadius: CLLocationDistance = 1000
    private let defaultRegionRadius: CLLocationDistance = 150
    
    // MARK: Init
    override init() {
        self.locationManager = CLLocationManager()
        self.coreDataStack = CoreDataStack.shared
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .other
        locationManager.pausesLocationUpdatesAutomatically = true
        
        managedObjectObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleRegionRefresh(reason: "Core Data change")
        }
        
        observeAuthorizationChanges()
    }
    
    deinit {
        if let observer = managedObjectObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        regionRefreshTask?.cancel()
    }
    
    // MARK: Public API
    func setUserPreference(enabled: Bool) {
        guard isPreferenceEnabled != enabled else { return }
        isPreferenceEnabled = enabled
        trackingPreferenceEnabled = enabled
        syncMonitoringState(reason: "User preference toggled")
    }
    
    func isLocationPermissionGranted() -> Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        default:
            break
        }
    }
    
    func refreshEventRegionsNow() {
        scheduleRegionRefresh(reason: "Manual refresh")
    }
    
    // MARK: Onboarding/Manual Location API
    func updateUserSession(_ session: UserSessionViewModel?) {
        userSession = session
    }
    
    func startLocationFlow(forceManual: Bool = false) {
        if forceManual {
            currentStep = .manual
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            currentStep = .permission
        case .denied, .restricted:
            currentStep = .manual
        default:
            // Permission already resolved; show manual entry only if tracking disabled.
            if !trackingPreferenceEnabled {
                currentStep = .manual
            } else {
                currentStep = .permission
            }
        }
    }

    /*
    func saveManualLocation(_ selection: ManualLocationSelection) async {
        guard !isSavingManualLocation else { return }
        guard let user = userSession?.currentUser else {
            manualLocationErrorMessage = "Sign in to save your location."
            return
        }
        
        isSavingManualLocation = true
        manualLocationErrorMessage = nil
        
        do {
            // Get the current profile
            guard let profile = try await userProfileRepository.getProfile(for: user) else {
                manualLocationErrorMessage = "Profile not found. Please create a profile first."
                isSavingManualLocation = false
                return
            }
            
            // Update profile with location data
            // We need to preserve existing profile data, so we'll need to get it first
            // For now, we'll update just the city and state, keeping showCityState as true
            _ = try await userProfileRepository.updateProfileWithForm(
                profile,
                displayName: profile.displayName,
                bio: profile.bio ?? "",
                dateOfBirth: profile.dateOfBirth,
                showAge: profile.showAge,
                genderCategory: profile.genderCategory ?? .unknown,
                genderIdentity: profile.genderIdentity ?? "",
                showGender: profile.showGender,
                city: selection.city,
                state: selection.state,
                showCityState: true,
                vibes: profile.vibes ?? Set<Vibe>()
            )
            // Don't dismiss the sheet - let the view handle the UI update
        } catch {
            manualLocationErrorMessage = "Failed to save location: \(error.localizedDescription)"
        }
        
        isSavingManualLocation = false
    }
     */

    private func observeAuthorizationChanges() {
        $authorizationStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .authorizedAlways, .authorizedWhenInUse:
                    // Permission granted - can stay on current step or go back to permission
                    break
                case .denied, .restricted:
                    if self.currentStep == .permission {
                        self.currentStep = .manual
                    }
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: Private Helpers
    private func syncMonitoringState(reason: String) {
        guard isPreferenceEnabled else {
            stopMonitoringAllRegions()
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled. Enable them in Settings."
            stopMonitoringAllRegions()
            return
        }
        
        guard isLocationPermissionGranted() else {
            stopMonitoringAllRegions()
            return
        }
        
        errorMessage = nil
        startLocationUpdatesIfNeeded()
        scheduleRegionRefresh(reason: reason)
    }
    
    private func startLocationUpdatesIfNeeded() {
        locationManager.startUpdatingLocation()
    }
    
    private func stopMonitoringAllRegions() {
        regionRefreshTask?.cancel()
        locationManager.stopUpdatingLocation()
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegionCount = 0
        isMonitoringEventRegions = false
    }
    
    private func scheduleRegionRefresh(reason: String) {
        guard isPreferenceEnabled, isLocationPermissionGranted() else { return }
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            errorMessage = "Geofencing unavailable on this device."
            return
        }
        
        regionRefreshTask?.cancel()
        regionRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshEventRegions(reason: reason)
        }
    }
    
    private func refreshEventRegions(reason: String) async {
        do {
            let descriptors = try await fetchUpcomingEventDescriptors(limit: maxRegions)
            apply(descriptors: descriptors)
        } catch {
            errorMessage = "Failed to refresh event regions: \(error.localizedDescription)"
        }
    }
    
    private func apply(descriptors: [EventRegionDescriptor]) {
        let identifiers = Set(descriptors.map(\.identifier))
        
        for region in locationManager.monitoredRegions where !identifiers.contains(region.identifier) {
            locationManager.stopMonitoring(for: region)
        }
        
        for descriptor in descriptors {
            if locationManager.monitoredRegions.contains(where: { $0.identifier == descriptor.identifier }) {
                continue
            }
            
            let region = CLCircularRegion(
                center: descriptor.coordinate,
                radius: descriptor.radius,
                identifier: descriptor.identifier
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }
        
        monitoredRegionCount = descriptors.count
        isMonitoringEventRegions = !descriptors.isEmpty
    }
    
    private func fetchUpcomingEventDescriptors(limit: Int) async throws -> [EventRegionDescriptor] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<EventItem> = EventItem.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "startTime != nil"),
                NSPredicate(format: "location != nil"),
                NSPredicate(format: "scheduleStatusRaw != %d", EventStatus.cancelled.rawValue)
            ])
            request.fetchLimit = limit * 2  // Fetch extras in case some locations are invalid.
            request.sortDescriptors = [
                NSSortDescriptor(key: "startTime", ascending: true)
            ]
            
            let events = try context.fetch(request)
            // Note: Place model no longer has coordinates/radius - geofencing disabled for now
            let descriptors: [EventRegionDescriptor] = []
            
            return Array(descriptors.sorted(by: { $0.startTime < $1.startTime }).prefix(limit))
        }
    }
    
    private func clampRadius(_ value: Double) -> CLLocationDistance {
        let sanitized = value.isFinite && value > 0 ? value : defaultRegionRadius
        return min(max(sanitized, minRegionRadius), maxRegionRadius)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        permissionDenied = {
            switch authorizationStatus {
            case .denied, .restricted:
                return true
            default:
                return false
            }
        }()
        syncMonitoringState(reason: "Authorization changed")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        lastRegionIdentifier = region.identifier
        lastRegionEvent = .entered
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        lastRegionIdentifier = region.identifier
        lastRegionEvent = .exited
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        errorMessage = "Region monitoring failed: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location update failed: \(error.localizedDescription)"
    }
}

// MARK: - EventRegionDescriptor
private struct EventRegionDescriptor {
    let identifier: String
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let startTime: Date
}
