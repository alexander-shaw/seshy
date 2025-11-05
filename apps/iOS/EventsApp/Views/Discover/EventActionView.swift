//
//  EventActionView.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

// TODO: Refactor as EventJoinView (Request / Join (Free) / Purchase Ticket).

import SwiftUI

struct EventActionView: View {
    let event: EventItem
    let action: EventAction

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.large) {
            HStack {
                Text(action == .watch ? "Watch" : "Join")
                    .titleStyle()
                    .padding(.top, theme.spacing.large)

                Spacer()
            }

            HStack {
                Text(event.name)
                    .headlineStyle()

                Spacer()
            }

            HStack {
                if let details = event.details {
                    Text(details)
                        .bodyTextStyle()
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, theme.spacing.medium)
                        .frame(alignment: .leading)
                }

                Spacer()
            }

            Spacer()
            
            if action == .watch {
                PrimaryButton(title: "Watch") {
                    dismiss()  // TODO: Implement functionality for Watch.
                }
            } else {
                if event.maxCapacity > 0 {
                    if event.remainingCapacity > 0 {
                        PrimaryButton(title: "Join") {
                            dismiss()  // TODO: Implement functionality for Join.
                        }
                    } else {
                        Text("Event is sold out :(")
                            .bodyTextStyle()
                            .foregroundStyle(theme.colors.error)
                    }
                } else {
                    PrimaryButton(title: "Join") {
                        dismiss()  // TODO: Implement functionality for Join.
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacing.medium)
        .presentationDetents([.fraction(0.5)])
    }
}
