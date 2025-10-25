//
//  AppearanceMode.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import UIKit

public enum AppearanceMode: Int16, Sendable {
    case system  = 0
    case darkMode = 1
    case lightMode = 2
}

public extension AppearanceMode {
    static func from(_ style: UIUserInterfaceStyle) -> AppearanceMode {
        switch style {
            case .light: return .lightMode
            case .dark: return .darkMode
            case .unspecified: return .system
            @unknown default:  return .system
        }
    }

    // Map to UIKit style.
    var uiStyle: UIUserInterfaceStyle {
        switch self {
            case .system: return .unspecified
            case .darkMode: return .dark
            case .lightMode: return .light
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI

// SwiftUI adapter (gated to iOS 13+).
// Handles future cases safely.
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension AppearanceMode {
    static func from(_ scheme: SwiftUI.ColorScheme?) -> AppearanceMode {
        guard let scheme else { return .system }
        switch scheme {
        case .light: return .lightMode
        case .dark:  return .darkMode
        @unknown default: return .system
        }
    }
}
#endif
