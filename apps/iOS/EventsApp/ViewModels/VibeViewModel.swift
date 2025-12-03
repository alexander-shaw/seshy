//
//  VibeViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
final class VibeViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var slug: String = ""
    @Published var category: VibeCategory = .custom
    @Published var systemDefined: Bool = false
    @Published var isActive: Bool = true
    
    // Vibe selection properties.
    @Published var searchText: String = ""
    @Published var selectedVibes: Set<Vibe> = []
    @Published var availableVibes: [Vibe] = []
    @Published var searchResults: [Vibe] = []
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var vibes: [Vibe] = []
    
    private let context: NSManagedObjectContext
    private let repository: VibeRepository
    private let userProfileRepository: UserProfileRepository
    private var vibe: Vibe?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserProfileId: UUID?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: VibeRepository = CoreVibeRepository(), userProfileRepository: UserProfileRepository = CoreUserProfileRepository()) {
        self.context = context
        self.repository = repository
        self.userProfileRepository = userProfileRepository
        
        setupSearchObserver()
        loadAvailableVibes()
    }
    
    func loadVibe(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedVibeDTO = try await repository.getVibe(by: id) {
                vibe = loadedVibeDTO
                populateFromVibe(loadedVibeDTO)
            }
        } catch {
            errorMessage = "Failed to load vibe:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadAllVibes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let vibeDTOs = try await repository.getAllVibes()
            vibes = vibeDTOs
        } catch {
            errorMessage = "Failed to load vibes:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadActiveVibes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let vibeDTOs = try await repository.getActiveVibes()
            vibes = vibeDTOs
        } catch {
            errorMessage = "Failed to load active vibes:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadVibesByCategory(_ category: VibeCategory) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let vibeDTOs = try await repository.getVibesByCategory(category)
            vibes = vibeDTOs
        } catch {
            errorMessage = "Failed to load vibes by category:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func searchVibes(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let vibeDTOs = try await repository.searchVibes(query: query)
            vibes = vibeDTOs
        } catch {
            errorMessage = "Failed to search vibes:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createVibe() async {
        guard !name.isEmpty else {
            errorMessage = "Vibe name is required."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let newVibeDTO = try await repository.createVibe(
                name: name,
                slug: slug.isEmpty ? generateSlug(from: name) : slug,
                category: category,
                systemDefined: systemDefined,
                isActive: isActive
            )
            
            let newVibe = newVibeDTO
            vibe = newVibe
            populateFromVibe(newVibe)
            vibes.append(newVibe)
        } catch {
            errorMessage = "Failed to create vibe:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateVibe() async {
        guard let currentVibe = vibe else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Update the existing vibe directly.
            currentVibe.name = name
            currentVibe.slug = slug.isEmpty ? generateSlug(from: name) : slug
            currentVibe.categoryRaw = category.rawValue
            currentVibe.systemDefined = systemDefined
            currentVibe.isActive = isActive
            currentVibe.updatedAt = Date()
            currentVibe.syncStatusRaw = SyncStatus.pending.rawValue
            
            if let result = try await repository.updateVibe(currentVibe) {
                vibe = result
                
                // Update in vibes array.
                if let index = vibes.firstIndex(where: { $0.id == currentVibe.id }) {
                    vibes[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to update vibe:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteVibe() async {
        guard let currentVibe = vibe else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deleteVibe(currentVibe.id)
            
            // Remove from vibes array.
            vibes.removeAll { $0.id == currentVibe.id }
            
            vibe = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete vibe:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func activateVibe() async {
        guard let currentVibe = vibe else { return }
        
        do {
            if let result = try await repository.activateVibe(currentVibe.id) {
                vibe = result
                isActive = true
                
                // Update in vibes array.
                if let index = vibes.firstIndex(where: { $0.id == currentVibe.id }) {
                    vibes[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to activate vibe:  \(error.localizedDescription)"
        }
    }
    
    func deactivateVibe() async {
        guard let currentVibe = vibe else { return }
        
        do {
            if let result = try await repository.deactivateVibe(currentVibe.id) {
                vibe = result
                isActive = false
                
                // Update in vibes array.
                if let index = vibes.firstIndex(where: { $0.id == currentVibe.id }) {
                    vibes[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to deactivate vibe:  \(error.localizedDescription)"
        }
    }
    
    func selectVibe(_ vibe: Vibe) {
        if !selectedVibes.contains(vibe) {
            selectedVibes.insert(vibe)
        }
    }
    
    func deselectVibe(_ vibe: Vibe) {
        selectedVibes.remove(vibe)
    }
    
    func toggleVibeSelection(_ vibe: Vibe) {
        if selectedVibes.contains(vibe) {
            selectedVibes.remove(vibe)
        } else {
            selectedVibes.insert(vibe)
        }
    }
    
    func clearSelection() {
        selectedVibes.removeAll()
    }
    
    func createNewVibe(from searchText: String) async {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newVibe = try await repository.createVibe(
                name: searchText,
                slug: generateSlug(from: searchText),
                category: .custom,
                systemDefined: false,
                isActive: true
            )
            
            availableVibes.append(newVibe)
            selectedVibes.insert(newVibe)
            self.searchText = ""
        } catch {
            errorMessage = "Failed to create vibe:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func saveSelectedVibes() async {
        guard let profileId = currentUserProfileId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // For now, add all selected vibes to the profile.
            // TODO: Compare with existing vibes and only add/remove the differences.
            _ = try await userProfileRepository.addVibesToProfile(profileId, vibes: selectedVibes)
        } catch {
            errorMessage = "Failed to save vibes:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func setCurrentUserProfileId(_ profileId: UUID) {
        currentUserProfileId = profileId
    }
    
    func loadExistingVibes() async {
        guard let profileId = currentUserProfileId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let existingVibes = try await userProfileRepository.getProfileVibes(profileId)
            selectedVibes = Set(existingVibes)
        } catch {
            errorMessage = "Failed to load existing vibes:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func loadAvailableVibes() {
        let request: NSFetchRequest<Vibe> = Vibe.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(key: "systemDefined", ascending: false),
            NSSortDescriptor(key: "categoryRaw", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        do {
            availableVibes = try context.fetch(request)
        } catch {
            errorMessage = "Failed to load cached vibes: \(error.localizedDescription)"
        }
    }
    
    private func performSearch(_ searchText: String) {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let filteredVibes = availableVibes.filter { vibe in
            vibe.name.localizedCaseInsensitiveContains(searchText)
        }
        
        searchResults = filteredVibes
    }
    
    // MARK: - COMPUTED PROPERTIES:
    var activeVibes: [Vibe] {
        return vibes.filter { $0.isActive }
    }
    
    var inactiveVibes: [Vibe] {
        return vibes.filter { !$0.isActive }
    }
    
    var systemDefinedVibes: [Vibe] {
        return vibes.filter { $0.systemDefined }
    }
    
    var userDefinedVibes: [Vibe] {
        return vibes.filter { !$0.systemDefined }
    }
    
    var vibesByCategory: [VibeCategory: [Vibe]] {
        return Dictionary(grouping: activeVibes) { $0.category }
    }
    
    var vibeCount: Int {
        return vibes.count
    }
    
    var selectedCount: Int {
        return selectedVibes.count
    }
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canEdit: Bool {
        return !systemDefined || vibe == nil
    }
    
    var canDelete: Bool {
        return !systemDefined
    }
    
    // Vibe selection computed properties.
    var canProceed: Bool {
        return selectedVibes.count >= 3
    }
    
    var selectedVibesCount: Int {
        return selectedVibes.count
    }
    
    var displayVibes: [Vibe] {
        if searchText.isEmpty {
            return availableVibes
        } else {
            return searchResults
        }
    }
    
    // MARK: - PRIVATE METHODS:
    private func populateFromVibe(_ vibe: Vibe) {
        name = vibe.name
        slug = vibe.slug
        category = vibe.category
        systemDefined = vibe.systemDefined
        isActive = vibe.isActive
    }
    
    private func resetForm() {
        name = ""
        slug = ""
        category = .custom
        systemDefined = false
        isActive = true
    }
    
    private func generateSlug(from name: String) -> String {
        return name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
    }
}
