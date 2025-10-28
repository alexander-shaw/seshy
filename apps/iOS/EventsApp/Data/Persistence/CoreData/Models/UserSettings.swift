//
//  UserSettings.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// This file defines the Core Data entity for storing user preferences and settings.
// It includes appearance mode, map preferences, and units settings.

import Foundation
import CoreData
import CoreDomain
import CoreLocation

@objc(UserSettings)
public class UserSettings: NSManagedObject {}

extension UserSettings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var id: UUID
    
    @NSManaged public var appearanceModeRaw: Int16  // Light or dark mode.  Default is system.
    @NSManaged public var preferredUnitsRaw: Int16

    // Map Preferences:
    // TODO: Center Coordinate Preference Priority:
    // (1) User's last known location.
    // (2) Else, default to known university's location via UserLogin.emailDomain.
    // (3) Else, default to last view.
    @NSManaged public var mapStyleRaw: Int16
    @NSManaged public var mapCenterLatitude: Double
    @NSManaged public var mapCenterLongitude: Double
    @NSManaged public var mapZoomLevel: Int16
    @NSManaged public var mapBearingDegrees: Double  // Course; degrees clockwise from true north.
    @NSManaged public var mapPitchDegrees: Double  // Tilt; vertical from ground.
    @NSManaged public var mapEndRollingDays: NSNumber?  // Rolling.  Nil means All.
    @NSManaged public var mapEndDate: Date?  // Hard set.  If nil, use mapEndRollingDays.

    // Relationships
    @NSManaged public var user: DeviceUser
}

extension UserSettings {
    public var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    public var preferredUnits: Units {
        get { Units(rawValue: preferredUnitsRaw) ?? .imperial }
        set { preferredUnitsRaw = newValue.rawValue }
    }
    
    public var mapStyle: MapStyle {
        get { MapStyle(rawValue: mapStyleRaw) ?? ((appearanceMode == .darkMode) ? .darkMap : .lightMap)}
        set { mapStyleRaw = newValue.rawValue }
    }

    public var mapCenterCoordinate: CLLocationCoordinate2D {
        get { CLLocationCoordinate2D(latitude: mapCenterLatitude, longitude: mapCenterLongitude) }
        set {
            mapCenterLatitude = newValue.latitude
            mapCenterLongitude = newValue.longitude
        }
    }
    
    public var hasMapEndDate: Bool {
        return mapEndDate != nil
    }
    
    public var mapDateRange: ClosedRange<Date>? {
        guard let endDate = mapEndDate else { return nil }
        return Date()...endDate  // From now to end date.
    }
}

// Local & Cloud Storage:
extension UserSettings: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int16

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
