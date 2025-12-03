//
//  EventOptionRow.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

struct EventOptionRow: View {
    let optionName: String
    let displayValue: String?
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: theme.spacing.medium) {
                // Show filled text when value exists.  Else, show plus icon.
                if let value = displayValue {
                    Text(optionName)
                        .captionTitleStyle()

                    Spacer()

                    Text(value)
                        .bodyTextStyle()
                        .multilineTextAlignment(.trailing)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                } else {
                    Text(optionName)
                        .foregroundStyle(theme.colors.mainText)
                        .captionTitleStyle()

                    Spacer()

                    IconButton(icon: "plus", style: .secondary) { onTap() }
                }
            }
            .frame(minHeight: theme.sizes.iconButton)
            .contentShape(Rectangle())
        }
    }
}
