//
//  Sizes.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct Sizes: Equatable {
    public var iconButton: CGFloat
    public var digitField: CGSize

    // Read-only:
    public let screenWidth: CGFloat
    public let screenHeight: CGFloat
    
    public init(iconButton: CGFloat, digitField: CGSize) {
        self.iconButton = iconButton
        self.digitField = digitField

        self.screenWidth = UIScreen.main.bounds.width
        self.screenHeight = UIScreen.main.bounds.height
    }

    public static let primary = Sizes(
        iconButton: 44,
        digitField: .init(width: 48, height: 60)
    )
}
