//
//  ThemeColorLibrary.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import Foundation

struct ThemeColorPreset: Identifiable {
    let id = UUID()
    let name: String
    let value: ThemeColorValue
}

enum ThemeColorLibrary {
    static let moodPresets: [ThemeColorPreset] = [
        ThemeColorPreset(name: "Neon", value: .linearGradient(angle: 45, stops: ["#0FF0FC", "#FC00FF"])),
        ThemeColorPreset(name: "Dark", value: .linearGradient(angle: 0, stops: ["#0F0F0F", "#232526"])),
        ThemeColorPreset(name: "Warm", value: .linearGradient(angle: 30, stops: ["#FF512F", "#DD2476"])),
        ThemeColorPreset(name: "Ice", value: .linearGradient(angle: 90, stops: ["#83A4D4", "#B6FBFF"])),
        ThemeColorPreset(name: "Exotic", value: .linearGradient(angle: 60, stops: ["#FF9A9E", "#FAD0C4"])),
        ThemeColorPreset(name: "Rage", value: .linearGradient(angle: 35, stops: ["#F83600", "#F9D423"])),
        ThemeColorPreset(name: "Euphoria", value: .linearGradient(angle: 120, stops: ["#7F00FF", "#E100FF"])),
        ThemeColorPreset(name: "Luxury", value: .linearGradient(angle: 0, stops: ["#434343", "#000000"])),
        ThemeColorPreset(name: "Underground", value: .linearGradient(angle: 75, stops: ["#414D0B", "#727A17"]))
    ]
    
    static let defaultSwatches: [String] = [
        "#FFFFFF", "#F5B8B0", "#FF7B54", "#FFBD35", "#FFE156",
        "#B3E283", "#4AD9A7", "#00C2FF", "#3F51B5", "#7C4DFF",
        "#D500F9", "#F50057"
    ]
    
    static let defaultGradientStops: [String] = ["#F83600", "#F9D423"]
    
    static let gradientAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]
}


















