//
//  TitleView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI

struct TitleView: View {
    var canGoBack: Bool = false  // Optional back button.
    @Environment(\.dismiss) private var dismiss

    let titleText: String  // Required.

    var trailingButton: AnyView? = nil  // Optional right-side button.

    var body: some View {
        ZStack(alignment: .center) {
            // OPTIONAL LEADING BACK BUTTON:
            if canGoBack {
                HStack {
                    IconButton(icon: "chevron.down") { dismiss() }
                    Spacer()
                }
            }

            // TITLE:
            HStack {
                Text(titleText)
                    .titleStyle()
                    .padding(.horizontal, canGoBack ? 44+Theme.Spacing.elements : 0)
                    .frame(minHeight: Theme.Size.iconButton)
                Spacer()
            }

            // OPTIONAL TRAILING BUTTON:
            if let trailingButton = trailingButton {
                HStack {
                    Spacer()
                    trailingButton
                }
            }
        }
        .padding(.vertical, Theme.Spacing.edges)
        .padding(.horizontal, Theme.Spacing.edges)
        .background(Theme.ColorPalette.background)
    }
}
