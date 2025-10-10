//
//  H3CellProtocol.swift
//  EventsApp
//
//  Created by Шоу on 10/10/25.
//

import Foundation

// A minimal surface that any model can adopt.
// Lets the shared package compute H3 resolution/index without knowing about the app’s storage layer.
public protocol H3CellProtocol {
    // H3 Spatial Quantization:
    var h3Index: Int64 { get }
    var resolution: Int16 { get }

    // Motion Context:
    var motionTypeRaw: Int16 { get }

    // Accuracies & Kinematics:
    var horizontalAccuracy: Double { get }
    var altitude: Double { get }
    var verticalAccuracy: Double { get }
    var speed: Double { get }
    var speedAccuracy: Double { get }
    var course: Double { get }
    var courseAccuracy: Double { get }
}
