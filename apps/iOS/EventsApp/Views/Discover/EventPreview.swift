//
//  EventPreview.swift
//  EventsApp
//
//  Created by Шоу on 10/28/25.
//

import SwiftUI
import CoreData
import CoreDomain

struct EventPreview: View {
    let event: UserEvent
    
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack(alignment: .center) {
            // MARK: Background Image:
            Group {
                if let firstMedia = event.previews?.first(where: { !$0.url.isEmpty }),
                   !firstMedia.url.isEmpty {
                    RemoteMediaImage(
                        urlString: firstMedia.url,
                        targetSize: CGSize(width: theme.sizes.screenWidth, height: theme.sizes.screenWidth * 5 / 4)
                    )
                } else {
                    Rectangle()
                        .fill(Color(hex: event.brandColor) ?? theme.colors.accent)
                }
            }
            .frame(width: theme.sizes.screenWidth, height: theme.sizes.screenWidth * 5 / 4)

            // MARK: Bottom Blur Gradient.
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.colors.background.opacity(0.50),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: (theme.sizes.screenWidth) / 3)

                Spacer()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        theme.colors.background.opacity(0.50)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: (theme.sizes.screenWidth) / 3)
            }
            
            // MARK: Content Overlay.
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                // Top: Location and Time.
                HStack(alignment: .top, spacing: theme.spacing.small / 2) {
                    if let place = event.location {
                        Image(systemName: "location")
                            .bodyTextStyle()

                        Text(place.name)
                            .bodyTextStyle()
                    }
                    
                    Spacer()
                    
                    if let startTime = event.startTime {
                        Image(systemName: "calendar")
                            .bodyTextStyle()

                        Text(startTime.formatted(date: .abbreviated, time: .omitted))
                            .bodyTextStyle()
                    }
                }
                .padding([.top, .horizontal], theme.spacing.medium)
                
                Spacer()
                
                // Bottom: Title.
                HStack(alignment: .bottom, spacing: theme.spacing.medium) {
                    VStack(alignment: .leading, spacing: theme.spacing.small) {
                        Text(event.name)
                            .titleStyle()
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding([.horizontal, .bottom], theme.spacing.medium)
            }
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
