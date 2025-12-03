//
//  TextStyles.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

// MARK: Public Sugar API:
// Single-call.
public extension View {
    func largeTitleStyle() -> some View { modifier(LargeTitleStyle()) }
    func titleStyle() -> some View { modifier(TitleStyle()) }
    func numbersTitleStyle() -> some View { modifier(NumbersTitleStyle()) }
    func headlineStyle() -> some View { modifier(HeadlineStyle()) }
    func iconStyle() -> some View { modifier(IconStyle()) }
    func buttonTextStyle() -> some View { modifier(ButtonTextStyle()) }
    func bodyTextStyle() -> some View { modifier(BodyTextStyle()) }
    func captionTitleStyle() -> some View { modifier(CaptionTitleStyle()) }
    func captionTextStyle() -> some View { modifier(CaptionTextStyle()) }
}

// MARK: Concrete Modifiers:
private struct LargeTitleStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.largeTitle)
            .foregroundStyle(theme.colors.mainText)
            .minimumScaleFactor(0.80)
            .lineLimit(1)  // Or nil.
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TitleStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.mainText)
            .minimumScaleFactor(0.90)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct NumbersTitleStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.title)
            .fontDesign(.monospaced)
            .foregroundStyle(theme.colors.mainText)
            .padding(.horizontal, theme.spacing.small)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HeadlineStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.headline)
            .foregroundStyle(theme.colors.mainText)
            .minimumScaleFactor(0.90)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct IconStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.icon)
            .foregroundStyle(theme.colors.mainText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ButtonTextStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.mainText)
            .fontWeight(.heavy)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BodyTextStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.mainText)
            .minimumScaleFactor(0.90)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CaptionTitleStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.caption)
            .textCase(.uppercase)
            .tracking(1.20)
            .foregroundStyle(theme.colors.offText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CaptionTextStyle: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.offText)
            .fixedSize(horizontal: false, vertical: true)
    }
}
