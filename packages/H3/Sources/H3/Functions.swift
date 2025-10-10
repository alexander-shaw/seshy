//
//  Functions.swift
//  EventsApp
//
//  Created by Шоу on 10/10/25.
//

import Foundation
import CoreLocation
import CoreGraphics
import CH3

// MARK: - CONVERSIONS:
@inline(__always) public func degsToRads(_ degrees: CLLocationDegrees) -> Double {
    return degrees * .pi / 180.0
}

@inline(__always) public func radsToDegs(_ radians: Double) -> Double {
    return radians * 180.0 / .pi
}

// MARK: Converts a geographic coordinate into a unique H3 Index.
// Converts the latitude & longitude from degrees to radians (H3 uses radians).
// Calls latLngToCell to get the H3 Index at a given resolution.
// Returns the H3 Index.
public func getIndex(for coordinate: CLLocationCoordinate2D, at resolution: Int16) -> UInt64 {
    var latLng = LatLng(
        lat: degsToRads(coordinate.latitude),
        lng: degsToRads(coordinate.longitude)
    )
    var h3: H3Index = 0
    latLngToCell(&latLng, Int32(resolution), &h3)
    return h3
}

// MARK: Best H3 Resolution for the given data.
// Resolution  =>  Edge Length  =>  Real-World Equivalent
// 0   =>  1,107,700 m  =>  Continental Region
// 1   =>  418,700 m    =>  Large US State (California)
// 2   =>  158,200 m    =>  Medium US State (Indiana)
// 3   =>  59,800 m     =>  Large Metropolitan Area (NYC)
// 4   =>  22,600 m     =>  City Scale (Downtown)
// 5   =>  8,500 m      =>  Small City / Urban District
// 6   =>  3,200 m      =>  Neighborhood / Campus
// 7   =>  1,200 m      =>  Large Park / Industrial Site
// 8   =>  460 m        =>  Large City Block / Commercial Complex
// 9   =>  174 m        =>  Single City Block
// 10  =>  66 m         =>  Medium/Large Building / Parking Lot
// 11  =>  25 m         =>  Apartment Building / Small School
// 12  =>  9.4 m        =>  House/Small Store
// 13  =>  3.5 m        =>  Street Width / Crosswalk
// 14  =>  1.3 m        =>  Sidewalk / Path / Interior Hallway
// 15  =>  0.5 m        =>  Furniture Layout / Small Indoor Room Feature
public func getOptimalResolution() -> Int16 {
    // TODO: Based on motionType.
    // TODO: Based on speed.
    return 12
}
