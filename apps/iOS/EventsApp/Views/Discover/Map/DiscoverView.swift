//
//  DiscoverView.swift
//  EventsApp
//
//  Created by Шоу on 10/1/25.
//

import SwiftUI
import CoreLocation
import MapboxMaps

enum DiscoverFlow: Identifiable {
    case openNewEvent
    
    var id: String {
        switch self {
            case .openNewEvent: return "openNewEvent"
        }
    }
}

struct DiscoverView: View {
    @Binding var bottomBarHeight: CGFloat
    @Environment(\.theme) private var theme
    
    @State private var discoverFlow: DiscoverFlow?

    // Map state - will be loaded from UserSettings
    @State private var centerCoordinate = CLLocationCoordinate2D(
        latitude: 46.7319,  // Washington State University default
        longitude: -117.1542
    )
    @State private var zoomLevel: Double = 15.0

    var body: some View {
        VStack(spacing: 0) {
            TitleView(titleText: "Discover", trailing: {
                IconButton(icon: "plus") {
                    discoverFlow = .openNewEvent
                }
            })

            // TODO: Date Picker Button.
            // Tap: Cycles through a short list: 2d -> 2w -> 1m -> 6m -> All.
            // Long-Press: Opens the native date picker, where user can select a date.
            // Haptic: Light on tap; medium on long-press.

            // Dark-styled Mapbox map with bottom padding for the bar.
            MapboxMapView(
                centerCoordinate: $centerCoordinate,
                zoomLevel: $zoomLevel,
                styleURI: .dark
            )
            .padding(.bottom, bottomBarHeight)
        }
        .background(theme.colors.background)
        .fullScreenCover(item: $discoverFlow) { flow in
            switch flow {
                case .openNewEvent:
                    NewEventView()
            }
        }
        .onAppear {
            loadMapPreferences()
        }
    }

    private func loadMapPreferences() {
        // TODO: Integrate with UserSettingsViewModel
        // Keeping defaults for now.
    }
}
