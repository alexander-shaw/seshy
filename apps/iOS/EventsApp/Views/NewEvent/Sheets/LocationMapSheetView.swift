//
//  LocationMapSheetView.swift
//  EventsApp
//
//  Created by Шоу on 12/19/25.
//

import SwiftUI
import CoreLocation

struct LocationMapSheetView: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var locationViewModel = LocationViewModel.shared
    
    var onDismiss: (() -> Void)?
    
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    @State private var searchSuggestions: [MapboxLocationSuggestion] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var centerCoordinate: CLLocationCoordinate2D
    @State private var zoomLevel: Double = 15.0
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>?
    
    // Default coordinate (WSU coordinates)
    private static let defaultCoordinate = CLLocationCoordinate2D(
        latitude: 46.7319,
        longitude: -117.1542
    )
    
    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        
        // Initialize with user's location if available, otherwise default
        if let userLocation = LocationViewModel.shared.lastKnownLocation {
            _centerCoordinate = State(initialValue: userLocation.coordinate)
        } else {
            _centerCoordinate = State(initialValue: Self.defaultCoordinate)
        }
    }
    
    var body: some View {
        Group {
            if !showSearch {
                // Map view mode
                ZStack {
                    MapboxMapView(
                        centerCoordinate: $centerCoordinate,
                        zoomLevel: $zoomLevel,
                        selectedCoordinate: selectedCoordinate,
                        onCoordinateSelected: { coordinate in
                            selectedCoordinate = coordinate
                        }
                    )
                    .ignoresSafeArea()
                    
                    // Top buttons: dismiss (leading) and search (trailing)
                    VStack {
                        HStack {
                            // Dismiss button (top leading) - only show if onDismiss is provided
                            if let onDismiss = onDismiss {
                                IconButton(icon: "chevron.down") {
                                    onDismiss()
                                }
                                .padding(.top, theme.spacing.medium)
                                .padding(.leading, theme.spacing.medium)
                            }
                            
                            Spacer()
                            
                            // Search icon button (top-right)
                            IconButton(icon: "magnifyingglass") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSearch = true
                                }
                            }
                            .padding(.top, theme.spacing.medium)
                            .padding(.trailing, theme.spacing.medium)
                        }
                        Spacer()
                        
                        // Disclaimer button at bottom (when location denied)
                        if locationViewModel.authorizationStatus == .denied || locationViewModel.authorizationStatus == .restricted {
                            Button(action: {
                                locationViewModel.requestPermission()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Location access is required to show nearby events")
                                        .captionTextStyle()
                                        .foregroundColor(theme.colors.mainText)
                                        .multilineTextAlignment(.center)
                                    Spacer()
                                }
                                .padding(.vertical, theme.spacing.small)
                                .padding(.horizontal, theme.spacing.medium)
                                .background(theme.colors.surface.opacity(0.9))
                                .clipShape(Capsule())
                            }
                            .padding(.bottom, theme.spacing.large)
                            .padding(.horizontal, theme.spacing.medium)
                        }
                    }
                }
            } else {
                // Search mode - map completely hidden
                VStack(spacing: 0) {
                    // Fixed top bar with search bar
                    HStack(spacing: theme.spacing.small) {
                        SearchBarView(
                            text: $searchText,
                            placeholder: "Search for an address",
                            autofocus: true
                        )
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSearch = false
                                searchText = ""
                                searchSuggestions = []
                            }
                        }) {
                            Text("Cancel")
                                .bodyTextStyle()
                                .foregroundColor(theme.colors.mainText)
                        }
                        .padding(.trailing, theme.spacing.medium)
                    }
                    .padding(.top, theme.spacing.medium)
                    .frame(height: 60)
                    .background(theme.colors.background)
                    
                    // Fixed results container - content changes but container stays stable
                    ZStack {
                        // Loading state
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // Results list
                        if !isSearching && !searchSuggestions.isEmpty {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(searchSuggestions) { suggestion in
                                        Button(action: {
                                            handleSuggestionTap(suggestion)
                                        }) {
                                            HStack(alignment: .top, spacing: theme.spacing.small) {
                                                if let iconName = suggestion.iconName {
                                                    Image(systemName: iconName)
                                                        .foregroundColor(theme.colors.offText)
                                                        .iconStyle()
                                                        .frame(width: 20, height: 20)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(suggestion.title)
                                                        .bodyTextStyle()
                                                        .foregroundColor(theme.colors.mainText)
                                                    
                                                    if let subtitle = suggestion.subtitle {
                                                        Text(subtitle)
                                                            .captionTextStyle()
                                                            .foregroundColor(theme.colors.offText)
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, theme.spacing.medium)
                                            .padding(.vertical, theme.spacing.small)
                                            .background(theme.colors.surface)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Divider()
                                            .background(theme.colors.surface)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // No results state
                        if !isSearching && searchText.isEmpty == false && searchSuggestions.isEmpty {
                            HStack {
                                Spacer()
                                Text("No results found")
                                    .captionTextStyle()
                                    .foregroundColor(theme.colors.offText)
                                    .padding()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.colors.background)
                }
                .background(theme.colors.background)
            }
        }
        .background(theme.colors.background)
    }
    
    // MARK: - Search
    
    private func performSearch(query: String) {
        // Cancel previous search task
        searchTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchSuggestions = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            do {
                let proximity = selectedCoordinate ?? centerCoordinate
                let suggestions = try await MapboxSearchService.shared.suggestions(
                    for: trimmedQuery,
                    limit: 8,
                    proximity: proximity
                )
                
                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchSuggestions = suggestions
                        self.isSearching = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isSearching = false
                        print("Search error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func handleSuggestionTap(_ suggestion: MapboxLocationSuggestion) {
        Task {
            // Try to get coordinate from cached suggestion
            if let coordinate = MapboxSearchService.shared.getCoordinate(for: suggestion.id) {
                await MainActor.run {
                    selectedCoordinate = coordinate
                    centerCoordinate = coordinate
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSearch = false
                        searchText = ""
                        searchSuggestions = []
                    }
                }
            } else {
                // If coordinate not available in cache, use map center as fallback
                // In production, we'd call the retrieve API here
                await MainActor.run {
                    selectedCoordinate = centerCoordinate
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSearch = false
                        searchText = ""
                        searchSuggestions = []
                    }
                }
            }
        }
    }
}
