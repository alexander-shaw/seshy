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

struct MapboxMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var zoomLevel: Double

    // Choose the style you want; default is .dark.
    var styleURI: StyleURI = .standard  // TODO: Implement dark & light mode via AppeareanceMode and UserSettings.

    func makeUIView(context: Context) -> UIView {
        // Create a simple container view.
        let containerView = UIView()
        
        // Initialize map with proper configuration using latest SDK API.
        let cameraOptions = CameraOptions(center: centerCoordinate, zoom: zoomLevel)
        let mapInitOptions = MapInitOptions(cameraOptions: cameraOptions, styleURI: styleURI)
        let mapView = MapboxMaps.MapView(frame: containerView.bounds, mapInitOptions: mapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add map to container.
        containerView.addSubview(mapView)
        
        // Store map view reference in coordinator.
        context.coordinator.mapView = mapView

        return containerView
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
