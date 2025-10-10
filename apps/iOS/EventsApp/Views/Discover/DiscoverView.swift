//
//  DiscoverView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI

struct DiscoverView: View {
    @Binding var bottomBarHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            TitleView(
                titleText: "Discover"
            )

            Spacer(minLength: 0)
        }
        .background(Theme.ColorPalette.background)
    }
}
