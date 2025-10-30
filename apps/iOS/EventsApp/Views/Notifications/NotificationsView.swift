//
//  NotificationsView.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI

struct NotificationsView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Recents")

            Spacer(minLength: 0)
        }
        .background(theme.colors.background)
    }
}
