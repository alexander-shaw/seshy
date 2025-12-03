//
//  MapboxMapView.swift
//  EventsApp
//
//  Created by Шоу on 10/20/25.
//

import SwiftUI
import MapboxMaps
import CoreLocation
import UIKit

struct MapboxMapView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var zoomLevel: Double
    var selectedCoordinate: CLLocationCoordinate2D?
    var onCoordinateSelected: ((CLLocationCoordinate2D) -> Void)?
    
    var styleURI: StyleURI = .dark

    func makeUIView(context: Context) -> UIView {
        // Initial camera based on the incoming bindings.
        let camera = CameraOptions(center: centerCoordinate, zoom: zoomLevel)

        // Create the Mapbox map view.
        let initOptions = MapInitOptions(cameraOptions: camera, styleURI: styleURI)
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: initOptions)

        // Keep a reference for later updates.
        context.coordinator.mapView = mapView
        context.coordinator.onCoordinateSelected = onCoordinateSelected

        // Ornament & gesture polish.
        mapView.ornaments.options.compass.visibility = .hidden
        mapView.ornaments.options.compass.position = .bottomRight
        mapView.ornaments.options.compass.margins = .init(x: 12, y: 12)
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.ornaments.options.logo.margins = .init(x: 12, y: 12)
        mapView.ornaments.options.attributionButton.margins = .init(x: 12, y: 12)
        
        // Set up tap gesture for dropping pins
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Set up long press gesture for dropping pins
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        mapView.addGestureRecognizer(longPressGesture)

        return mapView
    }

    func updateUIView(_ containerView: UIView, context: Context) {
        guard let mapView = context.coordinator.mapView else { return }
        
        // Update callback
        context.coordinator.onCoordinateSelected = onCoordinateSelected
        
        // Keep camera in sync with state.
        let cameraOptions = CameraOptions(center: centerCoordinate, zoom: zoomLevel)
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        // Update annotation for selected coordinate
        context.coordinator.updateAnnotation(coordinate: selectedCoordinate)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var mapView: MapboxMaps.MapView?
        var onCoordinateSelected: ((CLLocationCoordinate2D) -> Void)?
        var annotationManager: PointAnnotationManager?
        
        func updateAnnotation(coordinate: CLLocationCoordinate2D?) {
            guard let mapView = mapView else { return }
            
            // Get or create annotation manager
            if annotationManager == nil {
                guard let annotations = mapView.annotations else { return }
                do {
                    self.annotationManager = try annotations.makePointAnnotationManager(id: "selected-location-pin")
                } catch {
                    print("Failed to create annotation manager: \(error)")
                    return
                }
            }
            
            guard let manager = annotationManager else { return }
            
            // Update annotations
            if let coordinate = coordinate {
                var pointAnnotation = PointAnnotation(coordinate: coordinate)
                pointAnnotation.image = .init(image: UIImage(systemName: "mappin.circle.fill") ?? UIImage(), name: "pin")
                pointAnnotation.iconColor = StyleColor(UIColor.systemBlue)
                pointAnnotation.iconSize = 1.0
                
                do {
                    try manager.annotations = [pointAnnotation]
                } catch {
                    print("Failed to update annotations: \(error)")
                }
            } else {
                // Clear annotations if no coordinate
                do {
                    try manager.annotations = []
                } catch {
                    print("Failed to clear annotations: \(error)")
                }
            }
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView, gesture.state == .ended else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)
            onCoordinateSelected?(coordinate)
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let mapView = mapView, gesture.state == .began else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)
            onCoordinateSelected?(coordinate)
        }
    }
}
