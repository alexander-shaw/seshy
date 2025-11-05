//
//  LocationViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// TODO: Add a Core Motion View Model.

import Foundation
import SwiftUI
import Combine
import CoreLocation
import CoreDomain

@MainActor
final class LocationViewModel: ObservableObject {
    @Published var timestamp: Date = Date()
    @Published var motionType: MotionType = .unknown
    @Published var horizontalAccuracy: Double = 0.0
    @Published var altitude: Double = 0.0
    @Published var verticalAccuracy: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var speedAccuracy: Double = 0.0
    @Published var course: Double = 0.0
    @Published var courseAccuracy: Double = 0.0
    @Published var resolution: Int16 = 9
    @Published var h3Index: Int64 = 0
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    init() {
        // TODO: Implement location tracking.
    }
    
    func updateLocation(from location: CLLocation, motion: MotionType = .unknown) {
        populateFromLocation(location, motion: motion)
        // TODO: H3 cell creation and persistence will be implemented in a later version.
    }
    
    // MARK: - COMPUTED PROPERTIES:
    var trustScore: Double {
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
            case .walking, .running, .cycling, .driving: score *= 1.1
            case .stationary: score *= 1.0
            case .flying, .transition: score *= 0.9  // Erratic 3D movement -> less predictable.
            case .unknown: score *= 0.7  // No motion context -> penalized.
        }
        
        return score
    }
    
    var motionTypeDescription: String {
        switch motionType {
            case .unknown: return "Unknown"
            case .stationary: return "Stationary"
            case .walking: return "Walking"
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .driving: return "Driving"
            case .flying: return "Flying"
            case .transition: return "Transition"
        }
    }
    
    var speedDescription: String {
        if speed < 0 {
            return "Unknown"
        } else {
            return String(format: "%.1f m/s", speed)
        }
    }
    
    var courseDescription: String {
        if course < 0 {
            return "Unknown"
        } else {
            return String(format: "%.0f°", course)
        }
    }
    
    var accuracyDescription: String {
        return String(format: "±%.1fm", horizontalAccuracy)
    }
    
    // MARK: - PRIVATE METHODS:
    private func populateFromLocation(_ location: CLLocation, motion: MotionType) {
        timestamp = location.timestamp
        motionType = motion
        horizontalAccuracy = location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : 0.0
        altitude = location.altitude
        verticalAccuracy = location.verticalAccuracy >= 0 ? location.verticalAccuracy : 0.0
        speed = location.speed >= 0 ? location.speed : 0.0
        speedAccuracy = location.speedAccuracy >= 0 ? location.speedAccuracy : 0.0
        course = location.course >= 0 ? location.course : 0.0
        courseAccuracy = location.courseAccuracy >= 0 ? location.courseAccuracy : 0.0
    }
}
