//
//  MapboxSearchService.swift
//  EventsApp
//
//  Created by Шоу on 11/28/25.
//

import Foundation
import CoreLocation

/// Presentation model for Mapbox Search Box suggestions.
public struct MapboxLocationSuggestion: Identifiable, Hashable {
    public let id: String            // mapbox_id
    public let title: String
    public let subtitle: String?
    public let iconName: String?
}

enum MapboxSearchError: Error, LocalizedError {
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: Error?)
    case suggestionNotFound
    case sessionExpired
    case missingAccessToken
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let status):
            return "Mapbox search failed with status code \(status)."
        case .decodingFailed(let underlying):
            if let underlying = underlying {
                return "Could not decode Mapbox response: \(underlying.localizedDescription)"
            }
            return "Could not decode Mapbox response."
        case .suggestionNotFound:
            return "Suggestion is no longer available."
        case .sessionExpired:
            return "Location search session expired. Please try again."
        case .missingAccessToken:
            return "Missing Mapbox access token."
        }
    }
}

/// Wrapper around Mapbox Search Box API (`/suggest` + `/retrieve`) to support interactive search sessions.
@MainActor
final class MapboxSearchService {
    static let shared = MapboxSearchService()
    
    private let urlSession: URLSession
    private let accessToken: String
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Don't use snake_case conversion since we use custom CodingKeys
        return decoder
    }()
    
    private var sessionToken: String?
    private var sessionStartDate: Date?
    private let sessionTimeout: TimeInterval = 120 // seconds
    private var suggestionCache: [String: SearchBoxSuggestionDTO] = [:]
    
    private init(session: URLSession = .shared) {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String, !token.isEmpty else {
            fatalError("Missing MBXAccessToken in Info.plist – required for Mapbox Search Box API.")
        }
        self.accessToken = token
        self.urlSession = session
    }
    
    // MARK: - Public API
    
    func suggestions(
        for query: String,
        limit: Int = 8,
        proximity: CLLocationCoordinate2D? = nil,
        countryCodes: [String]? = nil
    ) async throws -> [MapboxLocationSuggestion] {
        let sanitized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else {
            cancelSession()
            suggestionCache.removeAll()
            return []
        }
        
        let token = ensureSessionToken()
        var components = URLComponents(string: "https://api.mapbox.com/search/searchbox/v1/suggest")!
        var params: [URLQueryItem] = [
            .init(name: "q", value: sanitized),
            .init(name: "access_token", value: accessToken),
            .init(name: "session_token", value: token),
            .init(name: "limit", value: "\(max(1, min(limit, 10)))"),
            .init(name: "language", value: Locale.preferredLanguages.first ?? "en"),
            .init(name: "types", value: "poi,address,place")
        ]
        if let proximity {
            params.append(.init(name: "proximity", value: "\(proximity.longitude),\(proximity.latitude)"))
        }
        if let countryCodes, !countryCodes.isEmpty {
            params.append(.init(name: "country", value: countryCodes.joined(separator: ",")))
        }
        components.queryItems = params
        
        let (data, response) = try await urlSession.data(for: URLRequest(url: components.url!))
        guard let http = response as? HTTPURLResponse else { throw MapboxSearchError.invalidResponse(statusCode: -1) }
        guard (200..<300).contains(http.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Mapbox API Error Response: \(responseString)")
            }
            throw MapboxSearchError.invalidResponse(statusCode: http.statusCode)
        }
        
        do {
            let payload = try decoder.decode(SearchBoxSuggestResponse.self, from: data)
            suggestionCache = Dictionary(uniqueKeysWithValues: payload.suggestions.map { ($0.id, $0) })
            
            return payload.suggestions.map {
                MapboxLocationSuggestion(
                    id: $0.id,
                    title: $0.name,
                    subtitle: $0.placeFormatted ?? $0.fullAddress,
                    iconName: $0.maki
                )
            }
        } catch {
            // Log the actual decoding error for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Mapbox Response JSON: \(responseString.prefix(500))") // Limit output
            }
            print("Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
            throw MapboxSearchError.decodingFailed(underlying: error)
        }
        
    }
    
    /// Retrieves full geometry/details for a previously suggested place.
    /*
    func resolveSuggestion(with id: String) async throws -> ManualLocationSelection {
        guard let token = sessionToken else { throw MapboxSearchError.sessionExpired }
        guard let cached = suggestionCache[id] else { throw MapboxSearchError.suggestionNotFound }
        
        var components = URLComponents(string: "https://api.mapbox.com/search/searchbox/v1/retrieve/\(id)")!
        components.queryItems = [
            .init(name: "access_token", value: accessToken),
            .init(name: "session_token", value: token)
        ]
        
        let (data, response) = try await urlSession.data(for: URLRequest(url: components.url!))
        guard let http = response as? HTTPURLResponse else { throw MapboxSearchError.invalidResponse(statusCode: -1) }
        guard (200..<300).contains(http.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Mapbox Retrieve API Error Response: \(responseString)")
            }
            throw MapboxSearchError.invalidResponse(statusCode: http.statusCode)
        }
        
        // Check if data is empty
        guard !data.isEmpty else {
            print("Mapbox Retrieve API returned empty response for suggestion ID: \(id)")
            print("Session token: \(token)")
            print("Cached suggestion: \(cached)")
            throw MapboxSearchError.decodingFailed(underlying: NSError(domain: "MapboxSearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response data is empty"]))
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Mapbox Retrieve Response (first 1000 chars): \(responseString.prefix(1000))")
        }
        
        do {
            let payload = try decoder.decode(SearchBoxRetrieveResponse.self, from: data)
            guard let feature = payload.features.first else {
                throw MapboxSearchError.decodingFailed(underlying: NSError(domain: "MapboxSearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No features in response"]))
            }
            
            // Try to get coordinate from feature geometry, or fall back to cached suggestion
            var coordinate: CLLocationCoordinate2D?
            if let geometry = feature.geometry, let coord = geometry.coordinate {
                coordinate = coord
            } else if let cachedCoord = cached.coordinates, cachedCoord.count >= 2 {
                coordinate = CLLocationCoordinate2D(latitude: cachedCoord[1], longitude: cachedCoord[0])
            }
            
            guard let finalCoordinate = coordinate else {
                throw MapboxSearchError.decodingFailed(underlying: NSError(domain: "MapboxSearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No coordinates available"]))
            }
            
            cancelSession() // stop billing for the interactive session
            
            let formatted = feature.properties?.placeFormatted ?? cached.placeFormatted ?? cached.name
            let city = feature.properties?.context?.place?.name ?? feature.properties?.context?.locality?.name ?? cached.context?.place?.name ?? cached.context?.locality?.name
            let state = feature.properties?.context?.region?.code ?? feature.properties?.context?.region?.name ?? cached.context?.region?.code ?? cached.context?.region?.name
            let country = feature.properties?.context?.country?.code ?? feature.properties?.context?.country?.name ?? cached.context?.country?.code ?? cached.context?.country?.name
            
            return ManualLocationSelection(
                formattedAddress: formatted,
                city: city,
                state: state,
                country: country,
                latitude: finalCoordinate.latitude,
                longitude: finalCoordinate.longitude
            )
        } catch {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Mapbox Retrieve Response JSON: \(responseString.prefix(500))")
            }
            print("Retrieve decoding error: \(error)")
            throw MapboxSearchError.decodingFailed(underlying: error)
        }
    }
     */

    func cancelSession() {
        sessionToken = nil
        sessionStartDate = nil
        suggestionCache.removeAll()
    }
    
    /// Gets the coordinate for a suggestion ID from the cache, if available
    func getCoordinate(for suggestionId: String) -> CLLocationCoordinate2D? {
        guard let cached = suggestionCache[suggestionId],
              let coords = cached.coordinates,
              coords.count >= 2 else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    }
    
    // MARK: - Private helpers
    
    private func ensureSessionToken() -> String {
        let now = Date()
        if let sessionToken,
           let start = sessionStartDate,
           now.timeIntervalSince(start) < sessionTimeout {
            return sessionToken
        }
        let newToken = UUID().uuidString
        sessionToken = newToken
        sessionStartDate = now
        return newToken
    }
}

// MARK: - DTOs

private struct SearchBoxSuggestResponse: Decodable {
    let suggestions: [SearchBoxSuggestionDTO]
    
    // Handle case where response might be an array directly
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as array first
        if let array = try? container.decode([SearchBoxSuggestionDTO].self) {
            self.suggestions = array
            return
        }
        
        // Otherwise decode as object with suggestions key
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.suggestions = try keyedContainer.decode([SearchBoxSuggestionDTO].self, forKey: .suggestions)
    }
    
    enum CodingKeys: String, CodingKey {
        case suggestions
    }
}

private struct SearchBoxSuggestionDTO: Decodable {
    let id: String          // mapbox_id
    let name: String
    let placeFormatted: String?
    let maki: String?
    let context: SearchBoxContext?
    let fullAddress: String?  // full_address - sometimes present
    let coordinates: [Double]?  // coordinates from geometry if present
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // mapbox_id is required
        self.id = try container.decode(String.self, forKey: .id)
        
        // name might be in different fields - try name first, then text
        if let nameValue = try? container.decode(String.self, forKey: .name) {
            self.name = nameValue
        } else if let textValue = try? container.decode(String.self, forKey: .text) {
            self.name = textValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.name, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected 'name' or 'text' field"))
        }
        
        // Optional fields
        self.placeFormatted = try? container.decode(String.self, forKey: .placeFormatted)
        self.maki = try? container.decode(String.self, forKey: .maki)
        self.context = try? container.decode(SearchBoxContext.self, forKey: .context)
        self.fullAddress = try? container.decode(String.self, forKey: .fullAddress)
        
        // Try to get coordinates from geometry if present
        if let geometry = try? container.decode(SearchBoxGeometry.self, forKey: .geometry) {
            self.coordinates = geometry.coordinates
        } else {
            self.coordinates = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "mapbox_id"
        case name
        case text
        case placeFormatted = "place_formatted"
        case maki
        case context
        case fullAddress = "full_address"
        case geometry
    }
}

private struct SearchBoxContext: Decodable {
    let country: SearchBoxContextItem?
    let region: SearchBoxContextItem?
    let place: SearchBoxContextItem?
    let locality: SearchBoxContextItem?
}

private struct SearchBoxContextItem: Decodable {
    let name: String?
    let code: String?
}

private struct SearchBoxRetrieveResponse: Decodable {
    let features: [SearchBoxFeature]
    
    // Handle both FeatureCollection format and direct features array
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as array of features first
        if let array = try? container.decode([SearchBoxFeature].self) {
            self.features = array
            return
        }
        
        // Otherwise decode as FeatureCollection object
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.features = try keyedContainer.decode([SearchBoxFeature].self, forKey: .features)
    }
    
    enum CodingKeys: String, CodingKey {
        case features
    }
}

private struct SearchBoxFeature: Decodable {
    let mapboxId: String?
    let geometry: SearchBoxGeometry?
    let properties: SearchBoxFeatureProperties?
    
    enum CodingKeys: String, CodingKey {
        case mapboxId = "mapbox_id"
        case geometry
        case properties
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapboxId = try? container.decode(String.self, forKey: .mapboxId)
        geometry = try? container.decode(SearchBoxGeometry.self, forKey: .geometry)
        properties = try? container.decode(SearchBoxFeatureProperties.self, forKey: .properties)
    }
}

private struct SearchBoxGeometry: Decodable {
    let coordinates: [Double]
    
    var coordinate: CLLocationCoordinate2D? {
        guard coordinates.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
    }
}

private struct SearchBoxFeatureProperties: Decodable {
    let name: String?
    let placeFormatted: String?
    let context: SearchBoxContext?
}

