//
//  UserSettingsDraft.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import Foundation
import CoreData
import CoreDomain

// A draft object for staging changes to UserSettings before applying them atomically.
// Allows multiple property changes to be applied together in a single save operation.
public struct UserSettingsDraft {
    public var appearanceModeRaw: Int16
    
    // Map Preferences.
    public var mapStyleRaw: Int16
    public var mapCenterLatitude: Double
    public var mapCenterLongitude: Double
    public var mapZoomLevel: Int16
    public var mapBearingDegrees: Double
    public var mapPitchDegrees: Double
    public var mapStartDate: Date?
    public var mapEndRollingDays: NSNumber?
    public var mapEndDate: Date?
    public var mapMaxDistance: Double?  // Maximum distance in meters.  Nil means show all results worldwide.

    // Initialize a draft from an existing UserSettings managed object.
    public init(from settings: UserSettings) {
        self.appearanceModeRaw = settings.appearanceModeRaw
        self.mapStyleRaw = settings.mapStyleRaw
        self.mapCenterLatitude = settings.mapCenterLatitude
        self.mapCenterLongitude = settings.mapCenterLongitude
        self.mapZoomLevel = settings.mapZoomLevel
        self.mapBearingDegrees = settings.mapBearingDegrees
        self.mapPitchDegrees = settings.mapPitchDegrees
        self.mapStartDate = settings.mapStartDate
        self.mapEndRollingDays = settings.mapEndRollingDays
        self.mapEndDate = settings.mapEndDate
        self.mapMaxDistance = settings.mapMaxDistance?.doubleValue
    }
    
    // Apply the draft changes to a UserSettings managed object.
    public func apply(to settings: UserSettings) {
        settings.appearanceModeRaw = self.appearanceModeRaw
        settings.mapStyleRaw = self.mapStyleRaw
        settings.mapCenterLatitude = self.mapCenterLatitude
        settings.mapCenterLongitude = self.mapCenterLongitude
        settings.mapZoomLevel = self.mapZoomLevel
        settings.mapBearingDegrees = self.mapBearingDegrees
        settings.mapPitchDegrees = self.mapPitchDegrees
        settings.mapStartDate = self.mapStartDate
        settings.mapEndRollingDays = self.mapEndRollingDays
        settings.mapEndDate = self.mapEndDate
        settings.mapMaxDistance = self.mapMaxDistance.map { NSNumber(value: $0) }
        
        // Mark as updated and pending sync.
        settings.updatedAt = Date()
        settings.syncStatusRaw = SyncStatus.pending.rawValue
    }
}

// MARK: - CONVENIENCE METHODS:
extension UserSettingsDraft {
    // Update the appearance mode.
    public mutating func updateAppearanceMode(_ mode: AppearanceMode) {
        appearanceModeRaw = mode.rawValue
    }
    
    // Update the map style.
    public mutating func updateMapStyle(_ style: MapStyle) {
        mapStyleRaw = style.rawValue
    }
    
    // Update the map center coordinate.
    public mutating func updateMapCenter(latitude: Double, longitude: Double) {
        mapCenterLatitude = latitude
        mapCenterLongitude = longitude
    }
    
    // Update the map zoom level.
    public mutating func updateMapZoomLevel(_ zoomLevel: Double) {
        mapZoomLevel = Int16(zoomLevel)
    }

    // Update the map bearing.
    public mutating func updateMapBearing(_ degrees: Double) {
        mapBearingDegrees = degrees
    }

    // Update the map pitch.
    public mutating func updateMapPitch(_ degrees: Double) {
        mapPitchDegrees = degrees
    }

    // Update the map end date.
    public mutating func updateMapStartDate(_ startDate: Date?) {
        mapStartDate = startDate
    }

    // Update the rolling days filter.
    public mutating func updateMapEndRollingDays(_ days: Int?) {
        if let days = days {
            mapEndRollingDays = NSNumber(value: days)
        } else {
            mapEndRollingDays = nil
        }
    }

    // Update the map end date.
    public mutating func updateMapEndDate(_ endDate: Date?) {
        mapEndDate = endDate
    }

    // Update the maximum distance filter (nil = show all worldwide).
    public mutating func updateMapMaxDistance(_ distance: Double?) {
        mapMaxDistance = distance
    }
}
