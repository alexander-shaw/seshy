//
//  PlaceViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
final class PlaceViewModel: ObservableObject {
    @Published var name: String = ""
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var userPlaces: [Place] = []
    
    private var context: NSManagedObjectContext {
        CoreDataStack.shared.viewContext
    }
    
    private var repository: PlaceRepository {
        CorePlaceRepository()
    }
    
    init() {}
    
    func loadPlace(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedPlace = try await repository.getPlace(by: id) {
                name = loadedPlace.name
            }
        } catch {
            errorMessage = "Failed to load place: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadAllPlaces() async {
        isLoading = true
        errorMessage = nil
        
        do {
            userPlaces = try await repository.getAllPlaces()
        } catch {
            errorMessage = "Failed to load places: \(error.localizedDescription)"
            userPlaces = []
        }
        
        isLoading = false
    }
    
    func createPlace(name: String) async throws -> Place {
        return try await repository.createPlace(name: name)
    }
    
    func selectPlace(_ place: Place) {
        name = place.name
    }
}
