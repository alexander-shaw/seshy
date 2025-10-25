//
//  MapStyle.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation
import UIKit

public enum MapStyle: Int16, Sendable {
    case darkMap = 0  // Default.
    case lightMap = 1
    case streets = 2
    case outdoors = 3
    case satellite = 4
    case satelliteStreets = 5
}

extension MapStyle {
    static let displayOrder: [MapStyle] = [.darkMap, .lightMap, .streets, .outdoors, .satellite, .satelliteStreets]

    // Whether this map type is allowed in a given appearance.
    fileprivate func supports(_ mode: AppearanceMode) -> Bool {
        switch self {
            case .darkMap:
                return mode == .darkMode
            case .lightMap:
                return mode == .lightMode
            case .streets, .outdoors, .satellite, .satelliteStreets:
                return true  // Available in all AppearanceModes.
        }
    }
}
