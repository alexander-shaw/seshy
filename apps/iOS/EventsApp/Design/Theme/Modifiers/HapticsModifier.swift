//
//  HapticsModifier.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

// Attach to any view to trigger a haptic on tap, without swallowing other gestures.
public struct HapticFeedbackModifier: ViewModifier {
    public enum Style {
        case light, medium, heavy, rigid, soft

        var generator: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
                case .light: return .light
                case .medium: return .medium
                case .heavy: return .heavy
                case .rigid: return .rigid
                case .soft: return .soft
            }
        }
    }

    private let style: Style

    public init(_ style: Style) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content.simultaneousGesture(TapGesture().onEnded {
            DispatchQueue.main.async {
                let g = UIImpactFeedbackGenerator(style: style.generator)
                g.prepare()
                g.impactOccurred()
            }
        })
    }
}

public extension View {
    func hapticFeedback(_ style: HapticFeedbackModifier.Style) -> some View {
        modifier(HapticFeedbackModifier(style))
    }
}
