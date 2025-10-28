//
//  WrapAroundLayout.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import SwiftUI

public struct WrapAroundLayout: Layout {
    @Environment(\.theme) private var theme

    public init() {}

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        let spacing: CGFloat = 12  // Default spacing.

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentRowWidth + subviewSize.width > maxWidth {
                totalHeight += maxRowHeight + spacing
                currentRowWidth = subviewSize.width
                maxRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + spacing
                maxRowHeight = max(maxRowHeight, subviewSize.height)
            }
        }
        totalHeight += maxRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        let spacing: CGFloat = theme.spacing.small  // Default spacing.

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentX + subviewSize.width > maxWidth {
                currentX = 0
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            subview.place(
                at: CGPoint(x: bounds.minX + currentX, y: bounds.minY + currentY),
                proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            )
            currentX += subviewSize.width + spacing
            maxRowHeight = max(maxRowHeight, subviewSize.height)
        }
    }
}
