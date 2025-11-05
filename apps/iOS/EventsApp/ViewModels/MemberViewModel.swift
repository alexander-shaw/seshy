//
//  MemberViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain

@MainActor
final class MemberViewModel: ObservableObject {
    @Published var userID: UUID = UUID()
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var avatarURL: String = ""
    @Published var role: MemberRole = .guest
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var members: [Member] = []
    
    private let context: NSManagedObjectContext
    private let repository: MemberRepository
    private var member: Member?
    private var eventID: UUID?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: MemberRepository = CoreMemberRepository()) {
        self.context = context
        self.repository = repository
    }
    
    func loadMember(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedMember = try await repository.getMember(by: id) {
                member = loadedMember
                populateFromMember(loadedMember)
            }
        } catch {
            errorMessage = "Failed to load member:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMembers(for eventID: UUID) async {
        isLoading = true
        errorMessage = nil
        self.eventID = eventID
        
        do {
            let memberDTOs = try await repository.getMembers(for: eventID)
            // TODO: Update repository implementation -- do not use DTOs here.
        } catch {
            errorMessage = "Failed to load members:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createMember(for eventID: UUID) async {
        guard !displayName.isEmpty else {
            errorMessage = "Display name is required."
            return
        }
        
        isSaving = true
        errorMessage = nil
        self.eventID = eventID
        
        do {
            let newMember = try await repository.createMember(
                for: eventID,
                userID: userID,
                role: role,
                displayName: displayName,
                username: username.isEmpty ? nil : username,
                avatarURL: avatarURL.isEmpty ? nil : avatarURL
            )
            
            member = newMember
            populateFromMember(newMember)
            members.append(newMember)
        } catch {
            errorMessage = "Failed to create member: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateMember() async {
        guard let currentMember = member else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Update member info.
            if let updatedMember = try await repository.updateMemberInfo(
                currentMember.id,
                displayName: displayName,
                username: username.isEmpty ? nil : username,
                avatarURL: avatarURL.isEmpty ? nil : avatarURL
            ) {
                member = updatedMember
                populateFromMember(updatedMember)
                
                // Update in members array.
                if let index = members.firstIndex(where: { $0.id == currentMember.id }) {
                    members[index] = updatedMember
                }
            }
            
            // Update member role if it changed.
            if let updatedMember = try await repository.updateMemberRole(currentMember.id, role: role) {
                member = updatedMember
                populateFromMember(updatedMember)
                
                // Update in members array.
                if let index = members.firstIndex(where: { $0.id == currentMember.id }) {
                    members[index] = updatedMember
                }
            }
        } catch {
            errorMessage = "Failed to update member: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteMember() async {
        guard let currentMember = member else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deleteMember(currentMember.id)
            
            // Remove from members array.
            members.removeAll { $0.id == currentMember.id }
            
            member = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete member: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateRole(_ newRole: MemberRole) async {
        guard let currentMember = member else { return }
        
        do {
            if let result = try await repository.updateMemberRole(currentMember.id, role: newRole) {
                member = result
                role = newRole
                populateFromMember(result)
                
                // Update in members array.
                if let index = members.firstIndex(where: { $0.id == currentMember.id }) {
                    members[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to update member role: \(error.localizedDescription)"
        }
    }
    
    func getHosts() async {
        guard let eventID = eventID else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            members = try await repository.getHosts(for: eventID)
        } catch {
            errorMessage = "Failed to load hosts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func getGuests() async {
        guard let eventID = eventID else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            members = try await repository.getGuests(for: eventID)
        } catch {
            errorMessage = "Failed to load guests: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func checkIfUserCanModifyEvent(userID: UUID) async -> Bool {
        guard let eventID = eventID else { return false }
        
        do {
            return try await repository.canUserModifyEvent(userID: userID, eventID: eventID)
        } catch {
            errorMessage = "Failed to check permissions: \(error.localizedDescription)"
            return false
        }
    }
    
    func checkIfUserIsMember(userID: UUID) async -> Bool {
        guard let eventID = eventID else { return false }
        
        do {
            return try await repository.isUserMember(of: eventID, userID: userID)
        } catch {
            errorMessage = "Failed to check membership: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - COMPUTED PROPERTIES:
    var hosts: [Member] {
        return members.filter { $0.roleRaw == MemberRole.host.rawValue }
    }
    
    var staff: [Member] {
        return members.filter { $0.roleRaw == MemberRole.staff.rawValue }
    }
    
    var guests: [Member] {
        return members.filter { $0.roleRaw == MemberRole.guest.rawValue }
    }
    
    var memberCount: Int {
        return members.count
    }
    
    var hostCount: Int {
        return hosts.count
    }
    
    var isValid: Bool {
        return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canEditRole: Bool {
        // Only hosts can edit roles.
        return role == .host
    }
    
    // MARK: - PRIVATE METHODS:
    private func populateFromMemberDTO(_ memberDTO: MemberDTO) {
        userID = memberDTO.userID
        displayName = memberDTO.displayName ?? ""
        username = memberDTO.username ?? ""
        avatarURL = memberDTO.avatarURL ?? ""
        role = MemberRole(rawValue: memberDTO.roleRaw) ?? .guest
    }
    
    private func populateFromMember(_ member: Member) {
        userID = member.userID
        displayName = member.displayName ?? ""
        username = member.username ?? ""
        avatarURL = member.avatarURL ?? ""
        role = member.role
    }
    
    private func resetForm() {
        userID = UUID()
        displayName = ""
        username = ""
        avatarURL = ""
        role = .guest
    }
}
