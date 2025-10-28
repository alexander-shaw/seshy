//
//  H3Node.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// Represents a single spatiotemporal observation (one moment in space-time).
// Retained locally for up to 30 days and then purged automatically.
// Raw node data is uploaded in daily gzipped batch files.

// Built on Uber’s H3 for hierarchical geospatial indexing and CoreMotion for motion insights.
// Captures sparse samples to support trajectory reconstruction and spatiotemporal inference.
// Maintains a short-term local history for on-device learning of user movement patterns and preferences.

import Foundation
import CoreData
import CoreLocation
import H3
import CoreDomain

@objc(H3Node)
public class H3Node: NSManagedObject, H3NodeProtocol {}

public extension H3Node {
    @nonobjc class func fetchRequest() -> NSFetchRequest<H3Node> {
        NSFetchRequest<H3Node>(entityName: "H3Node")
    }

    @NSManaged var id: UUID
    @NSManaged var timestamp: Date

    // Accuracies & Kinematics:
    @NSManaged var horizontalAccuracy: NSNumber?

    @NSManaged var altitude: NSNumber?
    @NSManaged var verticalAccuracy: NSNumber?

    @NSManaged var speed: NSNumber?
    @NSManaged var speedAccuracy: NSNumber?

    @NSManaged var course: NSNumber?
    @NSManaged var courseAccuracy: NSNumber?

    // Motion Context & H3 Spatial Quantization:
    @NSManaged var motionTypeRaw: Int16
    @NSManaged var resolution: Int16
    @NSManaged var h3Index: Int64  // MARK: Unique and indexed.
}

public extension H3Node {
    var motionType: MotionType {
        get { MotionType(rawValue: motionTypeRaw) ?? .unknown }
        set { motionTypeRaw = newValue.rawValue }
    }
}

// MARK: Time Of Day Features:
// For ML & quick bucketing.
public extension H3Node {

    // Seconds since local midnight (0...86_399).
    var secondsSinceMidnight: Int {
        let day = Calendar.current
        let components = day.dateComponents([.hour, .minute, .second], from: timestamp)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        return (hours * 3600) + (minutes * 60) + seconds
    }

    // Cyclical encoding of time of day.
    // Use in ML models to avoid discontinuity at midnight.
    var cyclicTimeOfDay: (sin: Double, cos: Double) {
        let seconds = Double(secondsSinceMidnight)
        let tau = 2.0 * Double.pi
        let angle = tau * (seconds / 86_400.0)
        return (sin(angle), cos(angle))
    }

    // 5-minute bucket index (0...287).
    var fiveMinuteBucket: Int16 {
        Int16(secondsSinceMidnight / 300)  // 300 seconds in 5 minutes.
    }
}

// MARK: Factory Methods:
public extension H3Node {
    static func make(in context: NSManagedObjectContext, location: CLLocation, motion: MotionType = .unknown) -> H3Node {
        let h3Node = H3Node(context: context)
        
        // Set basic properties.
        h3Node.id = UUID()
        h3Node.timestamp = location.timestamp
        h3Node.motionType = motion
        
        // Set location data.
        h3Node.horizontalAccuracy = location.horizontalAccuracy >= 0 ? NSNumber(value: location.horizontalAccuracy) : nil
        h3Node.altitude = location.altitude >= 0 ? NSNumber(value: location.altitude) : nil
        h3Node.verticalAccuracy = location.verticalAccuracy >= 0 ? NSNumber(value: location.verticalAccuracy) : nil
        h3Node.speed = location.speed >= 0 ? NSNumber(value: location.speed) : nil
        h3Node.speedAccuracy = location.speedAccuracy >= 0 ? NSNumber(value: location.speedAccuracy) : nil
        h3Node.course = location.course >= 0 ? NSNumber(value: location.course) : nil
        h3Node.courseAccuracy = location.courseAccuracy >= 0 ? NSNumber(value: location.courseAccuracy) : nil
        
        // Calculate H3 index and resolution.
        let resolution = getOptimalResolution()
        h3Node.resolution = resolution
        h3Node.h3Index = Int64(getHexagon(for: location.coordinate, at: resolution))
        
        return h3Node
    }
}

// Local & Cloud Storage:
extension H3Node: SyncTrackable {
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
