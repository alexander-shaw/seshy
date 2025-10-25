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
public func getHexagon(for coordinate: CLLocationCoordinate2D, at resolution: Int16) -> UInt64 {
    var latLng = LatLng(
        lat: degsToRads(coordinate.latitude),
        lng: degsToRads(coordinate.longitude)
    )
    var h3: H3Index = 0
    latLngToCell(&latLng, Int32(resolution), &h3)
    return h3
}

// MARK: Returns the center latitude & longitude of a given H3 Index.
// Initializes an empty LatLng struct.
// Calls cellToLatLng to fill in the center point of the given H3 Index.
// Returns them as a CLLocationCoordinate2D.
func h3CenterCoordinate(for index: UInt64) -> CLLocationCoordinate2D {
    var latLng = LatLng(lat: 0, lng: 0)
    cellToLatLng(index, &latLng)
    return CLLocationCoordinate2D(latitude: radsToDegs(latLng.lat), longitude: radsToDegs(latLng.lng))
}

// MARK: Returns the polygon boundary (vertices) of a given H3 cell; the coordinates of the hexagon's corners.
// Calls cellToBoundary, which populates a CellBoundary struct with up to 10 LatLng points.
// Uses Swift's Mirror to extract the C array (a fixed-size tuple) into a Swift array of LatLng.
// Converts each point from radians to degrees.
// Returns them as an array of CLLocationCoordinate2D points.
func h3Boundary(for index: UInt64) -> [CLLocationCoordinate2D] {
    var boundary = CellBoundary()
    cellToBoundary(index, &boundary)

    // Converts tuple to array.
    let verts = Mirror(reflecting: boundary.verts)
        .children
        .compactMap { $0.value as? LatLng }

    return verts.prefix(Int(boundary.numVerts)).map {
        CLLocationCoordinate2D(latitude: radsToDegs($0.lat), longitude: radsToDegs($0.lng))
    }
}

// MARK: Get all child hexagons at a higher resolution.  childResolution > resolution(of: index)
// If index is a hexagon at resolution 5 and childResolution is 7, 7^2 children of resolution 7 are turned.
// Determine how many child hexagons exist.
// Create an array to hold them.
// Fill the array with with actual child indexes.
// Return the result.
func h3ToChildren(of index: UInt64, childResolution: Int32) -> [UInt64] {
    var outSize: Int64 = 0
    cellToChildrenSize(index, childResolution, &outSize)
    var children = [UInt64](repeating: 0, count: Int(outSize))
    cellToChildren(index, childResolution, &children)
    return children
}

// MARK: Returns average square meters for each H3 resolution.
func hexagonArea(forResolution res: Int) -> Double? {
    // Approximate square meters per hexagon (from H3 documentation).
    let areaInSquareMeters: [Double] = [
        4250546.848, 607579.550, 86797.078, 12399.582, 1771.369,
        252.052, 36.008, 5.144, 0.735, 0.105,
        0.015, 0.002, 0.0003, 0.00004, 0.000005
    ]

    if res >= 0 && res < areaInSquareMeters.count {
        return areaInSquareMeters[res]
    } else {
        return nil  // Invalid resolution.
    }
}

// MARK: Best H3 Resolution for the given data.
// Resolution  =>  Edge Length  =>  Real-World Equivalent
// 0   =>  1,107 km  =>  Continental Region
// 1   =>  418 km    =>  Large US State (California)
// 2   =>  158 km    =>  Medium US State (Indiana)
// 3   =>  60 km     =>  Large Metropolitan Area (NYC)
// 4   =>  22 km     =>  City Scale (Downtown)
// 5   =>  8.5 km    =>  Small City / Urban District
// 6   =>  3.2 km    =>  Neighborhood / Campus
// 7   =>  1.2 km    =>  Large Park / Industrial Site
// 8   =>  460 m     =>  Large City Block / Commercial Complex
// 9   =>  174 m     =>  Single City Block
// 10  =>  66 m      =>  Medium/Large Building / Parking Lot
// 11  =>  25 m      =>  Apartment Building / Small School
// 12  =>  9.4 m     =>  House/Small Store
// 13  =>  3.5 m     =>  Street Width / Crosswalk
// 14  =>  1.3 m     =>  Sidewalk / Path / Interior Hallway
// 15  =>  0.5 m     =>  Furniture Layout / Small Indoor Room Feature
public func getOptimalResolution() -> Int16 {
    return 12  // TODO: Based on motionType and speed.
}


// MARK: Convert Mapbox Zoom Level to H3 Display Resolution.
// Mapbox Zoom => H3 Resolution => Notes
// 4-5  =>  3   =>  Large region hexagons (states & countries)
// 6    =>  4   =>  20-25 km
// 7    =>  5   =>  8-10 km
// 8    =>  6   =>  3-4 km
// 9    =>  7   =>  1-2 km
// 10   =>  8   =>  500 m
// 11   =>  9   =>  200 m
// 12   =>  10  =>  60-70 m
// 13   =>  11  =>  25 m
// 14   =>  12  =>  10 m
// 15   =>  13  =>  4 m
// 16   =>  14  =>  1-2 m (tiny and only for visualization)
public func displayH3Eesolution(forZoom zoom: Double) -> Int {
    return max(0, min(14, Int(round(zoom - 3))))
}
