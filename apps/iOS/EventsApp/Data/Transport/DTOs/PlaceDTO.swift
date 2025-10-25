//
//  PlaceDTO.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation

// Transport/Domain shape.
// Safe to cross actors and send to cloud.
public struct PlaceDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let name: String?
    public let details: String?
    public let streetAddress: String?
    public let city: String?
    public let stateRegion: String?
    public let roomNumber: String?
    public let latitude: Double
    public let longitude: Double
    public let radius: Double
    
    public let updatedAt: Date
    public let schemaVersion: Int
}
