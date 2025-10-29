//
//  Spacing.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct Spacing: Equatable {
    public var large: CGFloat
    public var medium: CGFloat
    public var small: CGFloat
    
    public init(
        large: CGFloat,
        medium: CGFloat,
        small: CGFloat
    ) {
        self.large = large
        self.medium = medium
        self.small = small
    }

    public static let primary = Spacing(
        large: 40,
        medium: 20,
        small: 10
    )
}
