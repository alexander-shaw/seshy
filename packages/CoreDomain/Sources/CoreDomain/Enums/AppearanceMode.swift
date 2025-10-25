//
//  AppearanceMode.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import Foundation
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

    // SwiftUI helper (nil means follow system).
    static func from(_ scheme: ColorScheme?) -> AppearanceMode {
        switch scheme {
            case .some(.light): return .lightMode
            case .some(.dark): return .darkMode
            case .none: return .system
        }
    }
}
