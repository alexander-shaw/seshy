//
//  MapboxMapView.swift
//  EventsApp
//
//  Created by Шоу on 10/20/25.
//

import SwiftUI
import MapboxMaps
import Combine
import CoreLocation
import CoreData

struct MapboxMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var zoomLevel: Double
    var events: [UserEvent] = []

    var styleURI: StyleURI = .standard

    func makeUIView(context: Context) -> UIView {
        // Initial camera based on the incoming bindings.
        let camera = CameraOptions(center: centerCoordinate, zoom: zoomLevel)

        // Create the Mapbox map view.
        let initOptions = MapInitOptions(cameraOptions: camera)
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: initOptions)

        // Keep a reference for later updates.
        context.coordinator.mapView = mapView

        // Ornament & gesture polish.
        mapView.ornaments.options.compass.visibility = .visible
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.ornaments.options.logo.margins = .init(x: 12, y: 12)
        mapView.ornaments.options.attributionButton.margins = .init(x: 12, y: 12)

        return mapView
    }

    func updateUIView(_ containerView: UIView, context: Context) {
        // Keep camera in sync with state.
        guard let mapView = context.coordinator.mapView else { return }
        let cameraOptions = CameraOptions(center: centerCoordinate, zoom: zoomLevel)
        mapView.mapboxMap.setCamera(to: cameraOptions)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var mapView: MapboxMaps.MapView?
    }
}
