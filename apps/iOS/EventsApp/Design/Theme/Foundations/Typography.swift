//
//  Typography.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct Typography: Equatable {
    public var largeTitle: Font
    public var title: Font
    public var headline: Font
    public var icon: Font
    public var body: Font
    public var caption: Font
    
    public init(
        largeTitle: Font,
        title: Font,
        headline: Font,
        icon: Font,
        body: Font,
        caption: Font
    ) {
        self.largeTitle = largeTitle
        self.title = title
        self.headline = headline
        self.icon = icon
        self.body = body
        self.caption = caption
    }

    // SF Pro Font Weights:
    // Ultralight -> Thin -> Light -> Regular -> Medium -> Semibold -> Bold -> Heavy -> Black
    public static let primary = Typography(
        largeTitle: .system(size: 48, weight: .heavy),
        title: .system(size: 28, weight: .bold),
        headline: .system(size: 22, weight: .bold),
        icon: .system(size: 18, weight: .bold),
        body: .system(size: 15, weight: .medium),
        caption: .system(size: 12, weight: .regular)
    )
}
