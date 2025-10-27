//
//  FeedbackGenerator.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import UIKit

public enum Feedback {
    public enum Impact: CaseIterable {
        case light, medium, heavy, soft, rigid
        public func fire() {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = {
                switch self {
                    case .light: return .light
                    case .medium: return .medium
                    case .heavy: return .heavy
                    case .soft: return .soft
                    case .rigid: return .rigid
                }
            }()
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.prepare(); gen.impactOccurred()
        }
    }

    public enum Selection {
        public static func changed() {
            let gen = UISelectionFeedbackGenerator()
            gen.prepare(); gen.selectionChanged()
        }
    }

    public enum Notice {
        case success, warning, error
        public func fire() {
            let gen = UINotificationFeedbackGenerator()
            gen.prepare()
            switch self {
            case .success: gen.notificationOccurred(.success)
            case .warning: gen.notificationOccurred(.warning)
            case .error:   gen.notificationOccurred(.error)
            }
        }
    }
}
