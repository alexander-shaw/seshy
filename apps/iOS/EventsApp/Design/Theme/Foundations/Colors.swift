//
//  Colors.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct Colors: Equatable {
    // Palette:
    public var accent: Color
    public var background: Color
    public var surface: Color
    public var mainText: Color
    public var offText: Color
    
    // Additional:
    public var success: Color
    public var error: Color
    public var warning: Color
    public var info: Color
    
    public init(
        accent: Color,
        background: Color,
        surface: Color,
        mainText: Color,
        offText: Color,
        success: Color,
        error: Color,
        warning: Color,
        info: Color
    ) {
        self.accent = accent
        self.background = background
        self.surface = surface
        self.mainText = mainText
        self.offText = offText
        self.success = success
        self.error = error
        self.warning = warning
        self.info = info
    }

    public static let darkMode = Colors(
        accent: .blue,
        background: Color(hex: "#121212") ?? .black,
        surface: Color(hex: "#292929") ?? .gray,
        mainText: Color(hex: "#FFFFFF") ?? .white,
        offText: Color(hex: "#B3B3B3") ?? .gray,
        
        success: .green,
        error: .red,
        warning: .orange,
        info: .blue
    )

    public static let lightMode = Colors(
        accent: .blue,
        background: Color(hex: "#FFFFFF") ?? .white,
        surface: Color(hex: "#F5F5F5") ?? .gray,
        mainText: Color(hex: "#000000") ?? .black,
        offText: Color(hex: "#525252") ?? .gray,

        success: .green,
        error: .red,
        warning: .orange,
        info: .blue
    )
}
