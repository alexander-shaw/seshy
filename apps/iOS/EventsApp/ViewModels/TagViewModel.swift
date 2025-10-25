//
//  TagViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages tag creation, editing, and selection functionality.
// Provides a reactive interface for SwiftUI views to work with tags including:
// - CRUD operations for tags (create, read, update, delete);
// - Tag search and filtering capabilities;
// - Tag selection for events and user profiles; and
// - Integration with Core Data persistence layer.

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain

@MainActor
final class TagViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var slug: String = ""
    @Published var category: TagCategory = .custom
    @Published var systemDefined: Bool = false
    @Published var isActive: Bool = true
    
    // Tag selection properties.
    @Published var searchText: String = ""
    @Published var selectedTags: Set<Tag> = []
    @Published var availableTags: [Tag] = []
    @Published var searchResults: [Tag] = []
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var tags: [Tag] = []
    
    private let context: NSManagedObjectContext
    private let repository: TagRepository
    private let userProfileRepository: UserProfileRepository
    private var tag: Tag?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserProfileId: UUID?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: TagRepository = CoreDataTagRepository(), userProfileRepository: UserProfileRepository = CoreDataUserProfileRepository()) {
        self.context = context
        self.repository = repository
        self.userProfileRepository = userProfileRepository
        
        setupSearchObserver()
        loadAvailableTags()
    }
    
    func loadTag(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedTagDTO = try await repository.getTag(by: id) {
                tag = loadedTagDTO
                populateFromTag(loadedTagDTO)
            }
        } catch {
            errorMessage = "Failed to load tag:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadAllTags() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tagDTOs = try await repository.getAllTags()
            tags = tagDTOs
        } catch {
            errorMessage = "Failed to load tags:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadActiveTags() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tagDTOs = try await repository.getActiveTags()
            tags = tagDTOs
        } catch {
            errorMessage = "Failed to load active tags:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadTagsByCategory(_ category: TagCategory) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tagDTOs = try await repository.getTagsByCategory(category)
            tags = tagDTOs
        } catch {
            errorMessage = "Failed to load tags by category:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func searchTags(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tagDTOs = try await repository.searchTags(query: query)
            tags = tagDTOs
        } catch {
            errorMessage = "Failed to search tags:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createTag() async {
        guard !name.isEmpty else {
            errorMessage = "Tag name is required."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let newTagDTO = try await repository.createTag(
                name: name,
                slug: slug.isEmpty ? generateSlug(from: name) : slug,
                category: category,
                systemDefined: systemDefined,
                isActive: isActive
            )
            
            let newTag = newTagDTO
            tag = newTag
            populateFromTag(newTag)
            tags.append(newTag)
        } catch {
            errorMessage = "Failed to create tag:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateTag() async {
        guard let currentTag = tag else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Update the existing tag directly.
            currentTag.name = name
            currentTag.slug = slug.isEmpty ? generateSlug(from: name) : slug
            currentTag.categoryRaw = category.rawValue
            currentTag.systemDefined = systemDefined
            currentTag.isActive = isActive
            currentTag.updatedAt = Date()
            currentTag.syncStatusRaw = SyncStatus.pending.rawValue
            
            if let result = try await repository.updateTag(currentTag) {
                tag = result
                
                // Update in tags array.
                if let index = tags.firstIndex(where: { $0.id == currentTag.id }) {
                    tags[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to update tag:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteTag() async {
        guard let currentTag = tag else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deleteTag(currentTag.id)
            
            // Remove from tags array.
            tags.removeAll { $0.id == currentTag.id }
            
            tag = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete tag:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func activateTag() async {
        guard let currentTag = tag else { return }
        
        do {
            if let result = try await repository.activateTag(currentTag.id) {
                tag = result
                isActive = true
                
                // Update in tags array.
                if let index = tags.firstIndex(where: { $0.id == currentTag.id }) {
                    tags[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to activate tag:  \(error.localizedDescription)"
        }
    }
    
    func deactivateTag() async {
        guard let currentTag = tag else { return }
        
        do {
            if let result = try await repository.deactivateTag(currentTag.id) {
                tag = result
                isActive = false
                
                // Update in tags array.
                if let index = tags.firstIndex(where: { $0.id == currentTag.id }) {
                    tags[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to deactivate tag:  \(error.localizedDescription)"
        }
    }
    
    func selectTag(_ tag: Tag) {
        if !selectedTags.contains(tag) {
            selectedTags.insert(tag)
        }
    }
    
    func deselectTag(_ tag: Tag) {
        selectedTags.remove(tag)
    }
    
    func toggleTagSelection(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func clearSelection() {
        selectedTags.removeAll()
    }
    
    func createNewTag(from searchText: String) async {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newTag = try await repository.createTag(
                name: searchText,
                slug: generateSlug(from: searchText),
                category: .custom,
                systemDefined: false,
                isActive: true
            )
            
            availableTags.append(newTag)
            selectedTags.insert(newTag)
            self.searchText = ""
        } catch {
            errorMessage = "Failed to create tag: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func saveSelectedTags() async {
        guard let profileId = currentUserProfileId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // For now, add all selected tags to the profile.
            // TODO: Compare with existing tags and only add/remove the differences.
            _ = try await userProfileRepository.addTagsToProfile(profileId, tags: selectedTags)
        } catch {
            errorMessage = "Failed to save tags: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func setCurrentUserProfileId(_ profileId: UUID) {
        currentUserProfileId = profileId
    }
    
    func loadExistingTags() async {
        guard let profileId = currentUserProfileId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let existingTags = try await userProfileRepository.getProfileTags(profileId)
            selectedTags = Set(existingTags)
        } catch {
            errorMessage = "Failed to load existing tags: \(error.localizedDescription)"
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
    
    private func loadAvailableTags() {
    }
    
    private func performSearch(_ searchText: String) {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let filteredTags = availableTags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(searchText)
        }
        
        searchResults = filteredTags
    }
    
    // MARK: - COMPUTED PROPERTIES:

    var activeTags: [Tag] {
        return tags.filter { $0.isActive }
    }
    
    var inactiveTags: [Tag] {
        return tags.filter { !$0.isActive }
    }
    
    var systemDefinedTags: [Tag] {
        return tags.filter { $0.systemDefined }
    }
    
    var userDefinedTags: [Tag] {
        return tags.filter { !$0.systemDefined }
    }
    
    var tagsByCategory: [TagCategory: [Tag]] {
        return Dictionary(grouping: activeTags) { $0.category }
    }
    
    var tagCount: Int {
        return tags.count
    }
    
    var selectedCount: Int {
        return selectedTags.count
    }
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canEdit: Bool {
        return !systemDefined || tag == nil
    }
    
    var canDelete: Bool {
        return !systemDefined
    }
    
    // Tag selection computed properties.
    var canProceed: Bool {
        return selectedTags.count >= 3
    }
    
    var selectedTagsCount: Int {
        return selectedTags.count
    }
    
    var displayTags: [Tag] {
        if searchText.isEmpty {
            return availableTags
        } else {
            return searchResults
        }
    }
    
    // MARK: - PRIVATE METHODS:

    private func populateFromTag(_ tag: Tag) {
        name = tag.name
        slug = tag.slug
        category = tag.category
        systemDefined = tag.systemDefined
        isActive = tag.isActive
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
