//
//  H3NodeProtocol.swift
//  EventsApp
//
//  Created by Шоу on 10/10/25.
//

// MARK: - H3Node Protocol:
// A minimal surface that any model can adopt.
// Lets the shared package compute H3 resolution & index without knowing about the app’s storage layer.

import Foundation

public protocol H3NodeProtocol {
    // Accuracies & Kinematics:
    // Sensors can be absent and should be optional for safety.
    var horizontalAccuracy: NSNumber? { get }

    var altitude: NSNumber? { get }  // Optional Double.
    var verticalAccuracy: NSNumber? { get }  // Optional Double.

    var speed: NSNumber? { get }  // Optional Double.
    var speedAccuracy: NSNumber? { get }  // Optional Double.

    var course: NSNumber? { get }  // Optional Double.
    var courseAccuracy: NSNumber? { get }  // Optional Double.

    // Core requirements:
    // H3 spatial quantization & semantics:
    var motionTypeRaw: Int16 { get }
    var resolution: Int16 { get }  // Determined by the above data.
    var h3Index: Int64 { get }  // Based on resolution.
}
