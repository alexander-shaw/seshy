//
//  DiscoverView.swift
//  EventsApp
//
//  Created by Шоу on 10/27/25.
//

import SwiftUI
import CoreData
import CoreDomain

struct EventListRow: View {
    let event: UserEvent
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(theme.colors.mainText)
                    .bold()

                Spacer()
                
                if let startTime = event.startTime {
                    Text(startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(theme.colors.offText)
                }
            }
            
            if let place = event.location {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)

                    Text(place.name)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.offText)
                }
            }
            
            if let details = event.details, !details.isEmpty {
                Text(details)
                    .font(.caption)
                    .foregroundColor(theme.colors.offText)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(theme.colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.surface, lineWidth: 1)
        )
    }
}
