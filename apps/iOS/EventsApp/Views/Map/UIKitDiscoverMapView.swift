//
//  UIKitDiscoverMapView.swift
//  EventsApp
//
//  Created by Шоу on 10/25/25.
//

import SwiftUI
import MapboxMaps

struct UIKitDiscoverMapView: UIViewControllerRepresentable {
    
    let events: [EventItem]
    let style: StyleURI
    
    func makeUIViewController(context: Context) -> DiscoverMapViewController {
        let controller = DiscoverMapViewController()
        controller.configure(events: events, style: style)
        return controller
    }
    
    func updateUIViewController(_ controller: DiscoverMapViewController, context: Context) {
        controller.configure(events: events, style: style)
    }
}
