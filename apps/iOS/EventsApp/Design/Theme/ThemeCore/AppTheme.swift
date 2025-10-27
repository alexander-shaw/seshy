//
//  AppTheme.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct AppTheme: ThemeProtocol, Equatable {
    public var colors: Colors
    public var typography: Typography
    public var spacing: Spacing
    public var sizes: Sizes

    public init(
        colors: Colors = .darkMode,
        typography: Typography = .primary,
        spacing: Spacing = .primary,
        sizes: Sizes = .primary
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.sizes = sizes
    }
    
    // Convenience initializers for different themes:
    public static let darkTheme = AppTheme(colors: .darkMode)
    public static let lightTheme = AppTheme(colors: .lightMode)
}
