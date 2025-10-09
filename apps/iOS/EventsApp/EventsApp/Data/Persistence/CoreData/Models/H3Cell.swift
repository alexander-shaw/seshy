//
//  H3Cell.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// MARK: Represents a single instance in space-time.
// Uses Uber's H3 library for hierarchical geospatial indexing and CoreMotion for motion data.
// Ingests sparse points for spatiotemporal inference and trajectory reconstruction.
// Maintains a local history and runs an on-device model to learn user preferences.

import Foundation
import CoreData
import CoreLocation

@objc(H3Cell)
public class H3Cell: NSManagedObject {}

extension H3Cell {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<H3Cell> {
        NSFetchRequest<H3Cell>(entityName: "H3Cell")
    }

    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date

    // H3 Spatial Quantization:
    @NSManaged public var h3Index: Int64  // MARK: Unique and indexed.
    @NSManaged public var resolution: Int16

    // Motion Context:
    @NSManaged public var motionTypeRaw: Int16

    // Accuracies & Kinematics:
    @NSManaged public var horizontalAccuracy: Double
    @NSManaged public var altitude: Double
    @NSManaged public var verticalAccuracy: Double
    @NSManaged public var speed: Double
    @NSManaged public var speedAccuracy: Double
    @NSManaged public var course: Double  // Track direction as angle.
    @NSManaged public var courseAccuracy: Double
}

extension H3Cell {
    public var motionType: MotionType {
        get { MotionType(rawValue: motionTypeRaw) ?? .unknown }
        set { motionTypeRaw = newValue.rawValue }
    }

    // MARK: Computed trust score.
    // Score | Reliability | Practical Meaning:
    // >= 0.03 | HIGH | Keep and use for predictions and visual updates.
    // 0.01-0.03 | MEDIUM | Might smooth or average nearby points.
    // 0.001-0.01 | LOW | Can still use if temporally consistent.
    // <0.001 | IGNORE | Likely drift, bounce, or no signal.

    public var trustScore: Double {
        // Guardrails to avoid divide-by-zero and wild spikes.
        let hAccuracy = max(horizontalAccuracy, 1.0)
        let vAccuracy = max(verticalAccuracy, 1.0)
        let sAccuracy = max(speedAccuracy, 0.1)
        let cAccuracy = max(courseAccuracy, 1.0)

        // Product of penalties (smaller accuracy => higher trust).
        var score = 1.0 / (hAccuracy * hAccuracy)  // Dominant, quadratic falloff.
        score *= 1.0 / (0.25 * vAccuracy + 1.0)  // Gentle linear penalty.
        score *= 1.0 / (0.5 * sAccuracy + 1.0)  // Gentle linear penalty.
        score *= 1.0 / (0.02 * cAccuracy + 1.0)  // Very gentle linear penalty.

        // Walking is more predictable than flying.
        switch motionType {
            case .cycling: score *= 1.25  // More predictable heading & speed.
            case .driving: score *= 1.2  // Smooth, road-constrained.
            case .running: score *= 1.1  // Mostly stable movement.
            case .walking: score *= 1.0  // Neutral baseline.
            case .flying: score *= 0.9  // Erratic 3D movement -> less predictable.
            case .unknown: score *= 0.7  // No motion context -> penalized.
        }

        return score
    }

    // MARK: CONVENIENCE INITIALIZER FROM CLLOCATION:
    public static func make(in context: NSManagedObjectContext, location: CLLocation, motion: MotionType = .unknown) -> H3Cell {
        let hexagon = H3Cell(context: context)
        hexagon.id = UUID()
        hexagon.timestamp = location.timestamp
        // TODO: p.h3Index = h3Index
        // TODO: p.resolution = resolution
        hexagon.motionType = motion

        // Fallbacks keep numbers finite.
        hexagon.horizontalAccuracy = location.horizontalAccuracy.isFinite ? location.horizontalAccuracy : 1000
        hexagon.verticalAccuracy = location.verticalAccuracy.isFinite ? location.verticalAccuracy : 1000
        hexagon.speed = location.speed.isFinite ? max(location.speed, 0) : -1
        hexagon.speedAccuracy = location.speedAccuracy.isFinite ? location.speedAccuracy : 999
        hexagon.course = location.course.isFinite ? location.course : -1
        hexagon.courseAccuracy = location.courseAccuracy.isFinite ? location.courseAccuracy : 999
        return hexagon
    }
}
