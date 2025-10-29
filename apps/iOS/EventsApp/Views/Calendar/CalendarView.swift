//
//  CalendarView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI

struct CalendarView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Next")

            Spacer(minLength: 0)
        }
        .background(theme.colors.background)
    }
}
