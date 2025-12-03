//
//  DiscoverMapViewController.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

/*
import UIKit
import MapboxMaps
import CoreLocation
import H3

class DiscoverMapViewController: UIViewController {
    
    private var mapView: MapboxMaps.MapView!
    private var hasAppeared = false
    
    var pendingEvents: [EventItem] = []
    var pendingStyle: StyleURI = .dark
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize MapView with MapInitOptions.
        let mapInitOptions = MapInitOptions(
            cameraOptions: CameraOptions(
                center: CLLocationCoordinate2D(latitude: 46.7319, longitude: -117.1542),
                zoom: 15.0
            ),
            styleURI: pendingStyle
        )
        
        mapView = MapboxMaps.MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasAppeared {
            hasAppeared = true
            renderMap()
        }
    }
    
    func configure(events: [EventItem], style: StyleURI) {
        self.pendingEvents = events
        self.pendingStyle = style
        
        if hasAppeared {
            mapView.mapboxMap.loadStyle(style) { [weak self] error in
                guard let self else { return }
                if let error = error {
                    print("Failed to load style:  \(error)")
                } else {
                    self.renderMap()
                }
            }
        }
    }

    // Add this helper anywhere inside DiscoverMapViewController.
    private func hideDefaultBuildingLayers() {
        // Hide any building layers that came with the style to prevent conflicts.
        let identifiers = mapView.mapboxMap.style.allLayerIdentifiers.map(\.id)
        for id in identifiers {
            if id.lowercased().contains("building") {
                // Low-level property set so we don't need to know the concrete layer type.
                try? mapView.mapboxMap.style.setLayerProperties(for: id, properties: ["visibility": "none"])
            }
        }
    }

    func renderMap() {
        // Clean old layers/sources.
        ["events-hexes-layer"].forEach { id in try? mapView.mapboxMap.removeLayer(withId: id) }
        ["events-hexes-source"].forEach { id in try? mapView.mapboxMap.removeSource(withId: id) }
        
        // Add 3D terrain.
        var demSource = RasterDemSource(id: "mapbox-dem")
        demSource.url = "mapbox://mapbox.terrain-rgb"
        demSource.tileSize = 512
        demSource.maxzoom = 14
        try? mapView.mapboxMap.addSource(demSource)
        
        var terrain = Terrain(sourceId: "mapbox-dem")
        terrain.exaggeration = .constant(2.0)
        try? mapView.mapboxMap.setTerrain(terrain)
        
        // Add 3D buildings.
        // All-or-nothing 3D buildings by zoom threshold.
        let buildingsVisibleFrom: Double = 15.5 // 16.0 for a harder snap.

        // Hide any default building layers the style may include.
        hideDefaultBuildingLayers()

        // Add our own buildings layer that only shows at or above the threshold.
        do {
            var buildingLayer = FillExtrusionLayer(id: "3d-buildings", source: "composite")
            buildingLayer.sourceLayer = "building"

            // Keep a wide maxZoom; rely on the opacity expression + minZoom for all-or-nothing.
            buildingLayer.minZoom = 0.0
            buildingLayer.maxZoom = 22.0

            // Only extrude features that have height.
            buildingLayer.filter = Exp(.gt) {
                Exp(.get) { "height" }
                0
            }

            // Snap from 0 → 0.85 opacity at the threshold zoom.
            // Below buildingsVisibleFrom, it is fully hidden (consistent nothing).
            // At/above, Mapbox will include all buildings present in the tiles at that zoom.
            buildingLayer.fillExtrusionOpacity = .expression(
                Exp(.step) {
                    Exp(.zoom)
                    0.0  // Default opacity below threshold.
                    buildingsVisibleFrom
                    0.85  // Opacity at/above threshold.
                }
            )

            buildingLayer.fillExtrusionColor  = .constant(StyleColor(.darkGray))
            buildingLayer.fillExtrusionHeight = .expression(Exp(.get) { "height" })
            buildingLayer.fillExtrusionBase   = .expression(Exp(.get) { "min_height" })

            try mapView.mapboxMap.addLayer(buildingLayer)
        } catch {
            print("Failed to add 3D buildings:  \(error)")
        }

        guard !pendingEvents.isEmpty else { 
            print("No events to display.")
            return
        }
        
        print("Rendering \(pendingEvents.count) events on map.")

        // Generate hexagons for events (with colors).
        let hexFeatures = geoJSONHexagons(from: pendingEvents)
        
        guard !hexFeatures.features.isEmpty else {
            print("No hexagon features generated.")
            return
        }
        
        var hexSource = GeoJSONSource(id: "events-hexes-source")
        hexSource.data = .featureCollection(hexFeatures)
        do {
            try mapView.mapboxMap.addSource(hexSource)
            print("Added hex source to map.")
        } catch {
            print("Failed to add hex source:  \(error)")
        }
        
        var hexLayer = FillLayer(id: "events-hexes-layer", source: "events-hexes-source")
        
        // Use data-driven colors from feature properties.
        hexLayer.fillColor = .expression(
            Exp(.toColor) {
                Exp(.get) { "color" }
            }
        )
        
        hexLayer.fillOpacity = .constant(0.4)
        
        // Outline matches fill color.
        hexLayer.fillOutlineColor = .expression(
            Exp(.toColor) {
                Exp(.get) { "color" }
            }
        )
        
        do {
            try mapView.mapboxMap.addLayer(hexLayer)
            print("Added hex layer to map.")
        } catch {
            print("Failed to add hex layer:  \(error)")
        }
    }
    
    private func geoJSONHexagons(from events: [EventItem]) -> FeatureCollection {
        print("Generating hexagons for \(events.count) events.")

        let features = events.compactMap { event -> Feature? in
            guard let place = event.location else {
                print("Event \(event.name) has no location.")
                return nil
            }
            
            let normalizedColor = event.themePrimaryHex ?? "#808080"
            print("Event: \(event.name), Place: \(place.name) at \(place.name) [\(normalizedColor)]")

            // Validate coordinates.
            guard place.latitude != 0 || place.longitude != 0 else {
                print("Skipping event with invalid place coordinates.")
                return nil
            }
            
            let (_, center, boundary) = bestHexagonForPlace(
                latitude: place.latitude,
                longitude: place.longitude,
                radiusMeters: place.radius
            )
            
            print("Hex center: (\(center.latitude), \(center.longitude)) and boundary points: \(boundary.count)")

            // Close the polygon if needed.
            var coords = boundary
            if let first = coords.first, let last = coords.last, first != last {
                coords.append(first)
            }
            
            // Create feature with event-specific properties.
            var feature = Feature(geometry: .polygon(Polygon([coords])))
            
            // Set color property for this event.
            feature.properties = ["color": JSONValue.string(normalizedColor)]

            return feature
        }
        
        print("Generated \(features.count) hexagon features.")
        return FeatureCollection(features: features)
    }
}
*/
