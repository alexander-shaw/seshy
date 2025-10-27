//
//  TitleView.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct TitleView<Trailing: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    public let titleText: String
    public var canGoBack: Bool = false
    public var backIcon: String = "chevron.down"
    public var onBack: (() -> Void)? = nil
    @ViewBuilder public var trailing: () -> Trailing

    public init(
        titleText: String,
        canGoBack: Bool = false,
        backIcon: String = "chevron.down",
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.titleText = titleText
        self.canGoBack = canGoBack
        self.backIcon = backIcon
        self.onBack = onBack
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: theme.spacing.small) {
            if canGoBack {
                IconButton(icon: backIcon) {
                    if let onBack { onBack() } else { dismiss() }
                }
                .padding(.leading, theme.spacing.small)
            }

            Text(titleText)
                .headlineStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .allowsTightening(false)
                .truncationMode(.tail)
                .padding(.leading, !canGoBack ? theme.spacing.medium : 0)

            Spacer()

            trailing()
        }
        .padding(.top, theme.spacing.small)
        .padding(.trailing, theme.spacing.small)
        .padding(.bottom, theme.spacing.small)
        .overlay(alignment: .bottom) {
            Divider()
                .foregroundStyle(theme.colors.surface)
        }
        .background(theme.colors.background)
    }
}
