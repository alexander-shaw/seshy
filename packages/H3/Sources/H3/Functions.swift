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
    degrees * .pi / 180.0
}

@inline(__always) public func radsToDegs(_ radians: Double) -> Double {
    radians * 180.0 / .pi
}

// MARK: - VALIDATION / CLAMP:
@inline(__always) private func clampResolution(_ res: Int) -> Int {
    // H3 supports 0...15
    max(0, min(15, res))
}

@inline(__always) private func isValidCoordinate(_ c: CLLocationCoordinate2D) -> Bool {
    c.latitude >= -90 && c.latitude <= 90 && c.longitude >= -180 && c.longitude <= 180
}

// MARK: - H3 WRAPPERS:
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
public func h3CenterCoordinate(for index: UInt64) -> CLLocationCoordinate2D {
    var latLng = LatLng(lat: 0, lng: 0)
    cellToLatLng(index, &latLng)
    return CLLocationCoordinate2D(latitude: radsToDegs(latLng.lat), longitude: radsToDegs(latLng.lng))
}

// MARK: Returns the polygon boundary (vertices) of a given H3 cell; the coordinates of the hexagon's corners.
// Calls cellToBoundary, which populates a CellBoundary struct with up to 10 LatLng points.
// Uses Swift's Mirror to extract the C array (a fixed-size tuple) into a Swift array of LatLng.
// Converts each point from radians to degrees.
// Returns them as an array of CLLocationCoordinate2D points.
public func h3Boundary(for index: UInt64) -> [CLLocationCoordinate2D] {
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

// H3 cell area in square meters (uses CH3 cellAreaKm2 and converts).
@inline(__always) public func h3CellAreaM2(_ index: UInt64) -> Double {
    var km2: Double = 0
    cellAreaKm2(index, &km2)
    return km2 * 1_000_000.0
}

// MARK: Average area by resolution (meters squared) — optional utility.
// Source: H3 average areas table (converted to m²).  Useful when fast lookup is needed without location-specific area variance.
public func averageHexAreaM2(forResolution res: Int) -> Double? {
    // avg km² per cell by res (H3 docs) × 1e6
    let avgKm2: [Double] = [
        4250546.848, 607579.550, 86797.078, 12399.582, 1771.369,
        252.052, 36.008, 5.144, 0.735, 0.105,
        0.015, 0.002, 0.0003, 0.00004, 0.000005, 0.0000007
    ]

    guard res >= 0 && res < avgKm2.count else { return nil }
    return avgKm2[res] * 1_000_000.0
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
public func displayH3Resolution(forZoom zoom: Double) -> Int {
    return max(0, min(14, Int(round(zoom - 3))))
}

// MARK: Best single hex for a Place with latitude, longitude, and radius.
// Picks a single H3 hexagon that:
//  + covers at least minCoverage (default 80%) of the circle area (hex may be inside the circle);
//  + is not too big relative to the circle (bounded by maxOversize, default 1.25x);
//  + prefers larger hexagons (lower H3 resolution) within the acceptable band;
//  + and falls back to the closest-by-area hex, if no candidate matches.

// The minimum/coarsest allowed resolution is 10 (configurable), and we search up to maxRes (default 15).
public func bestHexagonForPlace(
    latitude: Double,
    longitude: Double,
    radiusMeters: Double,
    minRes: Int = 9,
    maxRes: Int = 16,
    minCoverage: Double = 0.80,
    maxOversize: Double = 1.20
) -> (resolution: Int, center: CLLocationCoordinate2D, boundary: [CLLocationCoordinate2D]) {
    // Input validation & normalization:
    precondition(radiusMeters > 0, "radiusMeters must be > 0")
    let clampedMin = clampResolution(minRes)
    let clampedMax = clampResolution(maxRes)
    precondition(clampedMin <= clampedMax, "minRes must be <= maxRes")

    var coverage = minCoverage
    var oversize = maxOversize
    if coverage <= 0 { coverage = 0.01 }
    if coverage >= 1 { coverage = 0.99 }
    if oversize <= coverage { oversize = coverage + 0.05 }  // Auto-repair.

    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    precondition(isValidCoordinate(coordinate), "Invalid coordinate.")

    // Target circle area:
    let circleAreaM2 = Double.pi * radiusMeters * radiusMeters
    let minAreaM2 = coverage * circleAreaM2
    let maxAreaM2 = oversize * circleAreaM2

    struct Candidate {
        let res: Int
        let index: UInt64
        let areaM2: Double
    }

    var candidates: [Candidate] = []
    var closestByArea: Candidate? = nil
    var smallestAbsDiff: Double = .infinity

    // Search from coarse -> fine:
    // Prefer bigger cells when acceptable.
    for res in clampedMin...clampedMax {
        let idx = getHexagon(for: coordinate, at: Int16(res))
        let area = h3CellAreaM2(idx)

        let absDiff = abs(area - circleAreaM2)
        if absDiff < smallestAbsDiff || (absDiff == smallestAbsDiff && (closestByArea == nil || res < closestByArea!.res)) {
            smallestAbsDiff = absDiff
            closestByArea = Candidate(res: res, index: idx, areaM2: area)
        }

        if area >= minAreaM2 && area <= maxAreaM2 {
            candidates.append(Candidate(res: res, index: idx, areaM2: area))
        }
    }

    // Select preferred: lowest res among acceptable; else, closest-by-area.
    let chosen: Candidate
    if let preferred = candidates.sorted(by: { lhs, rhs in
        if lhs.res != rhs.res { return lhs.res < rhs.res }  // Prefer larger hex.
        return abs(lhs.areaM2 - circleAreaM2) < abs(rhs.areaM2 - circleAreaM2)
    }).first {
        chosen = preferred
    } else if let fallback = closestByArea {
        chosen = fallback
    } else {
        // Extremely unlikely: default to minRes at the coordinate.
        let idx = getHexagon(for: coordinate, at: Int16(clampedMin))
        chosen = Candidate(res: clampedMin, index: idx, areaM2: h3CellAreaM2(idx))
    }

    let center = h3CenterCoordinate(for: chosen.index)
    let boundary = h3Boundary(for: chosen.index)
    return (resolution: chosen.res, center: center, boundary: boundary)
}
