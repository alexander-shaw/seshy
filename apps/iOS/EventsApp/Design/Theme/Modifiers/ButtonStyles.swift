//
//  ButtonStyles.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct CollapseButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    private let pressedScale: CGFloat

    public init(pressedScale: CGFloat = 0.90) {
        self.pressedScale = pressedScale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}
