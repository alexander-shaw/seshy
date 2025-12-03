//
//  ThemeColorValue.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import SwiftUI

enum ThemeColorValue: Equatable {
    case solid(hex: String)
    case linearGradient(angle: Double, stops: [String])
    
    var primaryHex: String {
        switch self {
        case .solid(let hex):
            return hex
        case .linearGradient(_, let stops):
            return stops.first ?? "#FFFFFF"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .solid(let hex):
            return [Color(hex: hex) ?? .white]
        case .linearGradient(_, let stops):
            return stops.compactMap { Color(hex: $0) }
        }
    }
}

enum ThemeColorParser {
    static func parse(_ value: String) -> ThemeColorValue? {
        guard !value.isEmpty else { return nil }
        if value.hasPrefix("#") {
            return .solid(hex: sanitizedHex(value))
        }
        
        if value.hasPrefix("linear:") {
            let components = value.components(separatedBy: ":")
            guard components.count == 3 else { return nil }
            let angleString = components[1]
            let stopsString = components[2]
            let stops = stopsString.split(separator: ",").map { sanitizedHex(String($0)) }.filter { !$0.isEmpty }
            guard let angle = Double(angleString), !stops.isEmpty else { return nil }
            return .linearGradient(angle: angle, stops: Array(stops.prefix(3)))
        }
        
        // Plain hex without leading #.
        if value.count == 6 {
            return .solid(hex: "#\(value.uppercased())")
        }
        
        return nil
    }
    
    static func encode(_ value: ThemeColorValue) -> String {
        switch value {
        case .solid(let hex):
            return sanitizedHex(hex)
        case .linearGradient(let angle, let stops):
            let stopString = stops.map { sanitizedHex($0) }.joined(separator: ",")
            return "linear:\(Int(angle)):\(stopString)"
        }
    }
    
    static func normalizedString(from value: String) -> String {
        if let parsed = parse(value) {
            return encode(parsed)
        }
        return sanitizedHex(value)
    }
    
    static func primaryHex(from value: String) -> String {
        if let parsed = parse(value) {
            return parsed.primaryHex
        }
        return sanitizedHex(value)
    }
    
    static func sanitizedHex(_ hex: String) -> String {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !text.hasPrefix("#") {
            text = "#\(text)"
        }
        if text.count == 7 {
            return text
        }
        // Invalid entries fallback to white to avoid crashes.
        return "#FFFFFF"
    }
}

