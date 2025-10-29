//
//  H3AggregatedEdgeDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct H3AggregatedEdgeDTO: Codable, Sendable, Equatable {
    public let id: String
    public let fromHexIndex: Int64
    public let toHexIndex: Int64
    public let motionTypeRaw: Int16
    
    // Coverage.
    public let firstTraversedAt: Date
    public let lastTraversedAt: Date
    public let traverseCount: Int64
    
    // Time aggregates.
    public let sumTime: Double
    public let maxTime: Double
    public let minTime: Double
    
    // Distance aggregates.
    public let sumDistance: Double
    public let maxDistance: Double
    public let minDistance: Double
    
    // Elevation aggregates.
    public let sumElevationDelta: Double?
    public let maxElevationDelta: Double?
    public let minElevationDelta: Double?
    public let elevationSamples: Int64
    
    public let updatedAt: Date
    public let schemaVersion: Int
}

