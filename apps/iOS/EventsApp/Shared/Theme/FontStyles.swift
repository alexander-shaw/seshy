//
//  FontStyles.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI

extension Theme {
    struct Font {
        static let largeTitle = SwiftUI.Font.system(size: 34, weight: .black)
        static let title = SwiftUI.Font.system(size: 28, weight: .black)
        static let headline = SwiftUI.Font.system(size: 24, weight: .heavy)
        static let icon = SwiftUI.Font.system(size: 20, weight: .heavy)
        static let body = SwiftUI.Font.system(size: 15, weight: .bold)
        static let caption = SwiftUI.Font.system(size: 12, weight: .regular)
    }
}

// MARK: - LARGE TEXT:
extension View {
    func helloTitleStyle() -> some View {
        self.modifier(HelloTitleStyle())
    }
    
    func largeTitleStyle() -> some View {
        self.modifier(LargeTitleStyle())
    }

    func titleStyle() -> some View {
        self.modifier(TitleStyle())
    }
    
    func headlineStyle() -> some View {
        self.modifier(HeadlineStyle())
    }
    
    func numbersTitleStyle() -> some View {
        self.modifier(NumbersTitleStyle())
    }
}

struct HelloTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 54, weight: .black))
            .tracking(1.20)
            .foregroundStyle(Theme.ColorPalette.mainText)
    }
}

struct LargeTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.largeTitle)
            .foregroundStyle(Theme.ColorPalette.mainText)
    }
}

struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.title)
            .foregroundStyle(Theme.ColorPalette.mainText)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.ColorPalette.mainText)
    }
}

struct NumbersTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .monospaced()
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.ColorPalette.mainText)
    }
}

// MARK: - CONTENT TEXT:
extension View {
    func bodyTextStyle() -> some View {
        self.modifier(BodyTextStyle())
    }
    
    func capitalCaptionStyle() -> some View {
        self.modifier(CapitalCaptionStyle())
    }
    
    func capsuleTagStyle(themeColor: Color = Theme.ColorPalette.accent, isSelected: Bool = false) -> some View {
        self.modifier(CapsuleTagStyle(themeColor: themeColor, isSelected: isSelected))
    }
    
    func captionTextStyle() -> some View {
        self.modifier(CaptionTextStyle())
    }
}

struct BodyTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.body)
            .foregroundStyle(Theme.ColorPalette.offText)
    }
}

struct CapitalCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.caption)
            .textCase(.uppercase)
            .tracking(1.20)
            .foregroundStyle(Theme.ColorPalette.offText)
    }
}

struct CapsuleTagStyle: ViewModifier {
    var themeColor: Color
    var isSelected: Bool

    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .font(Theme.Font.caption)
            .fontWeight(.bold)
            .foregroundStyle(isSelected ? Theme.ColorPalette.mainText : Theme.ColorPalette.offText)
            .padding(.vertical, Theme.Spacing.elements)
            .padding(.horizontal, Theme.Spacing.elements * 1.25)
            .background(isSelected ? AnyShapeStyle(themeColor) : AnyShapeStyle(.clear))
            .overlay(
                Capsule()
                    .stroke(isSelected ? AnyShapeStyle(themeColor) : AnyShapeStyle(Theme.ColorPalette.surface), lineWidth: 4)
            )
            .clipShape(Capsule())
    }
}

struct CaptionTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.ColorPalette.offText)
    }
}

// MARK: - HAPTIC FEEDBACK:
// LIGHT:  Soft and subtle.                  Light button taps (unlocking).
// MEDIUM: Noticeable but not overwhelming.  Standard button taps (confirmation).
// HEAVY:  Stronger and more pronounced.     Major confirmations (game interactions or achievements).
// RIGID:  Short, sharp, and crisp.          Toggle switches.
// SOFT:   Gentle.                           Swiping and soft, fluid animations.
// MARK: - HAPTIC FEEDBACK:
extension View {
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) -> some View {
        self.modifier(HapticFeedbackModifier(style: style))
    }
}

struct HapticFeedbackModifier: ViewModifier {
    var style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(TapGesture().onEnded {  // Runs alongside existing gestures without blocking them.
                DispatchQueue.main.async {
                    let generator = UIImpactFeedbackGenerator(style: style)
                    generator.prepare()
                    generator.impactOccurred()
                }
            })
    }
}
