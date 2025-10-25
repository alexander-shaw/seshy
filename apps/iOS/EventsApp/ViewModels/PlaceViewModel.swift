//
//  PlaceViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages place/location data for events.
// Provides a reactive interface for SwiftUI views to work with places including:
// - Place creation and editing;
// - Location search and validation;
// - Address management and geocoding; and
// - Integration with Core Data persistence layer.

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreLocation
import CoreDomain

@MainActor
final class PlaceViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var details: String = ""
    @Published var streetAddress: String = ""
    @Published var city: String = ""
    @Published var stateRegion: String = ""
    @Published var roomNumber: String = ""
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var radius: Double = 10.0
    @Published var maxCapacity: Int64 = 100
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var places: [Place] = []
    
    private var context: NSManagedObjectContext {
        CoreDataStack.shared.viewContext
    }
    
    private var repository: PlaceRepository {
        CoreDataPlaceRepository()
    }
    private var place: Place?
    
    // Public getter for the current place.
    var currentPlace: Place? {
        return place
    }
    
    init() {
        // Lazy properties will be initialized when first accessed.
    }
    
    func loadPlace(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedPlace = try await repository.getPlace(by: id) {
                place = loadedPlace
                populateFromPlace(loadedPlace)
            }
        } catch {
            errorMessage = "Failed to load place: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createPlace() async {
        isSaving = true
        errorMessage = nil
        
        do {
            let newPlace = try await repository.createPlace(
                name: name.isEmpty ? nil : name,
                details: details.isEmpty ? nil : details,
                streetAddress: streetAddress.isEmpty ? nil : streetAddress,
                city: city.isEmpty ? nil : city,
                stateRegion: stateRegion.isEmpty ? nil : stateRegion,
                roomNumber: roomNumber.isEmpty ? nil : roomNumber,
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                maxCapacity: maxCapacity
            )
            
            place = newPlace
            populateFromPlace(newPlace)
        } catch {
            errorMessage = "Failed to create place: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updatePlace() async {
        guard let currentPlace = place else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Update the existing place directly.
            currentPlace.name = name.isEmpty ? nil : name
            currentPlace.details = details.isEmpty ? nil : details
            currentPlace.streetAddress = streetAddress.isEmpty ? nil : streetAddress
            currentPlace.city = city.isEmpty ? nil : city
            currentPlace.stateRegion = stateRegion.isEmpty ? nil : stateRegion
            currentPlace.roomNumber = roomNumber.isEmpty ? nil : roomNumber
            currentPlace.latitude = latitude
            currentPlace.longitude = longitude
            currentPlace.radius = radius
            currentPlace.maxCapacity = NSNumber(value: maxCapacity)
            currentPlace.updatedAt = Date()
            currentPlace.syncStatusRaw = SyncStatus.pending.rawValue
            
            place = try await repository.updatePlace(currentPlace)
            populateFromPlace(place!)
        } catch {
            errorMessage = "Failed to update place: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deletePlace() async {
        guard let currentPlace = place else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deletePlace(currentPlace)
            place = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete place: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func searchPlaces(query: String) async {
        // Do not search if query is empty or too short.
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            places = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("PlaceViewModel: Searching for places with query: '\(query)'")
            places = try await repository.searchPlaces(query: query.trimmingCharacters(in: .whitespacesAndNewlines))
            print("PlaceViewModel: Found \(places.count) places")
        } catch {
            print("PlaceViewModel: Search error: \(error)")
            errorMessage = "Failed to search places: \(error.localizedDescription)"
            places = []
        }
        
        isLoading = false
    }
    
    func findPlacesNearby(latitude: Double, longitude: Double, radius: Double = 1000) async {
        isLoading = true
        errorMessage = nil
        
        do {
            places = try await repository.findPlacesNearby(
                latitude: latitude,
                longitude: longitude,
                radius: radius
            )
        } catch {
            errorMessage = "Failed to find nearby places: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadAllPlaces() async {
        isLoading = true
        errorMessage = nil
        
        do {
            places = try await repository.getAllPlaces()
        } catch {
            errorMessage = "Failed to load places: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func findOrCreatePlace(
        name: String?,
        details: String?,
        streetAddress: String?,
        city: String?,
        stateRegion: String?,
        roomNumber: String?,
        latitude: Double,
        longitude: Double,
        radius: Double
    ) async throws -> Place {
        return try await repository.findOrCreatePlace(
            name: name,
            details: details,
            streetAddress: streetAddress,
            city: city,
            stateRegion: stateRegion,
            roomNumber: roomNumber,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            maxCapacity: maxCapacity
        )
    }
    
    func setLocationFromCoordinate(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
    
    func setLocationFromLocation(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
    
    // MARK: - INTERACTIVE PLACE CREATION METHODS:
    
    func createPlaceAtCoordinate(_ coordinate: CLLocationCoordinate2D, radius: Double = 10.0) {
        setLocationFromCoordinate(coordinate)
        self.radius = radius
    }
    
    func updatePlaceRadius(_ newRadius: Double) {
        radius = max(5.0, min(1000.0, newRadius))  // Clamp between 5 m and 1 km.
    }
    
    func clearPlaceLocation() {
        latitude = 0.0
        longitude = 0.0
        radius = 10.0
    }
    
    func hasValidLocation() -> Bool {
        return latitude != 0.0 && longitude != 0.0
    }
    
    // MARK: - COMPUTED PROPERTIES:

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        if !name.isEmpty {
            return name
        } else if !streetAddress.isEmpty {
            return streetAddress
        } else if !city.isEmpty {
            return city
        } else {
            return "Unknown Location"
        }
    }
    
    var fullAddress: String {
        var components: [String] = []
        
        if !streetAddress.isEmpty {
            components.append(streetAddress)
        }
        
        if !city.isEmpty {
            components.append(city)
        }
        
        if !stateRegion.isEmpty {
            components.append(stateRegion)
        }
        
        return components.joined(separator: ", ")
    }
    
    var isValid: Bool {
        return latitude != 0.0 && longitude != 0.0
    }
    
    var hasAddress: Bool {
        return !streetAddress.isEmpty || !city.isEmpty || !stateRegion.isEmpty
    }
    
    // MARK: - PRIVATE METHODS:
    
    private func populateFromPlaceDTO(_ placeDTO: PlaceDTO) {
        name = placeDTO.name ?? ""
        details = placeDTO.details ?? ""
        streetAddress = placeDTO.streetAddress ?? ""
        city = placeDTO.city ?? ""
        stateRegion = placeDTO.stateRegion ?? ""
        roomNumber = placeDTO.roomNumber ?? ""
        latitude = placeDTO.latitude
        longitude = placeDTO.longitude
        radius = placeDTO.radius
    }
    
    private func populateFromPlace(_ place: Place) {
        name = place.name ?? ""
        details = place.details ?? ""
        streetAddress = place.streetAddress ?? ""
        city = place.city ?? ""
        stateRegion = place.stateRegion ?? ""
        roomNumber = place.roomNumber ?? ""
        latitude = place.latitude
        longitude = place.longitude
        radius = place.radius
        maxCapacity = place.maxCapacity?.int64Value ?? 100
    }
    
    private func resetForm() {
        name = ""
        details = ""
        streetAddress = ""
        city = ""
        stateRegion = ""
        roomNumber = ""
        latitude = 0.0
        longitude = 0.0
        radius = 10.0
        maxCapacity = 100
    }
}
