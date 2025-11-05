//
//  InviteViewModel.swift
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
final class InviteViewModel: ObservableObject {
    @Published var userID: UUID = UUID()
    @Published var type: InviteType = .invite
    @Published var status: InviteStatus = .pending
    @Published var token: String = ""
    @Published var expiresAt: Date?
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var invites: [Invite] = []
    
    private let context: NSManagedObjectContext
    private let repository: InviteRepository
    private var invite: Invite?
    private var eventID: UUID?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: InviteRepository = CoreInviteRepository()) {
        self.context = context
        self.repository = repository
    }
    
    func loadInvite(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedInvite = try await repository.getInvite(by: id) {
                invite = loadedInvite
                populateFromInvite(loadedInvite)
            }
        } catch {
            errorMessage = "Failed to load invite:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadInvites(for eventID: UUID) async {
        isLoading = true
        errorMessage = nil
        self.eventID = eventID
        
        do {
            let inviteDTOs = try await repository.getInvites(for: eventID)
            // TODO: Update repository implementation -- do not use DTOs here.
        } catch {
            errorMessage = "Failed to load invites:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadInvitesForUser(_ userID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            invites = try await repository.getInvitesForUser(userID)
        } catch {
            errorMessage = "Failed to load user invites:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createInvite(for eventID: UUID) async {
        isSaving = true
        errorMessage = nil
        self.eventID = eventID
        
        do {
            let newInvite = try await repository.createInvite(
                for: eventID,
                userID: userID,
                type: type,
                token: token.isEmpty ? nil : token
            )
            
            invite = newInvite
            populateFromInvite(newInvite)
            invites.append(newInvite)
        } catch {
            errorMessage = "Failed to create invite:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateInviteStatus(_ newStatus: InviteStatus) async {
        guard let currentInvite = invite else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            if let updatedInvite = try await repository.updateInviteStatus(currentInvite.id, status: newStatus) {
                invite = updatedInvite
                status = newStatus
                
                // Update in invites array.
                if let index = invites.firstIndex(where: { $0.id == currentInvite.id }) {
                    invites[index] = updatedInvite
                }
            }
        } catch {
            errorMessage = "Failed to update invite status:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteInvite() async {
        guard let currentInvite = invite else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deleteInvite(currentInvite.id)
            
            // Remove from invites array.
            invites.removeAll { $0.id == currentInvite.id }
            
            invite = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete invite:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func getPendingInvites() async {
        guard let eventID = eventID else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            invites = try await repository.getPendingInvites(for: eventID)
        } catch {
            errorMessage = "Failed to load pending invites:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func cleanupExpiredInvites() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let count = try await repository.cleanupExpiredInvites()

            // Reload invites after cleanup.
            if let eventID = eventID {
                invites = try await repository.getInvites(for: eventID)
            }
        } catch {
            errorMessage = "Failed to cleanup expired invites: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func approveInvite() async {
        await updateInviteStatus(.approved)
    }
    
    func declineInvite() async {
        await updateInviteStatus(.declined)
    }
    
    func revokeInvite() async {
        await updateInviteStatus(.revoked)
    }
    
    // MARK: - COMPUTED PROPERTIES:
    var pendingInvites: [Invite] {
        return invites.filter { $0.statusRaw == InviteStatus.pending.rawValue }
    }
    
    var approvedInvites: [Invite] {
        return invites.filter { $0.statusRaw == InviteStatus.approved.rawValue }
    }
    
    var declinedInvites: [Invite] {
        return invites.filter { $0.statusRaw == InviteStatus.declined.rawValue }
    }
    
    var expiredInvites: [Invite] {
        return invites.filter { $0.statusRaw == InviteStatus.expired.rawValue }
    }
    
    var revokedInvites: [Invite] {
        return invites.filter { $0.statusRaw == InviteStatus.revoked.rawValue }
    }
    
    var inviteCount: Int {
        return invites.count
    }
    
    var pendingCount: Int {
        return pendingInvites.count
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var isValid: Bool {
        return userID != UUID() && !isExpired
    }
    
    var canApprove: Bool {
        return status == .pending && !isExpired
    }
    
    var canDecline: Bool {
        return status == .pending && !isExpired
    }
    
    var canRevoke: Bool {
        return status == .pending || status == .approved
    }
    
    // MARK: - PRIVATE METHODS:
    private func populateFromInviteDTO(_ inviteDTO: InviteDTO) {
        userID = inviteDTO.userID
        type = InviteType(rawValue: inviteDTO.typeRaw) ?? .invite
        status = InviteStatus(rawValue: inviteDTO.statusRaw) ?? .pending
        token = inviteDTO.token ?? ""
        expiresAt = inviteDTO.expiresAt
    }
    
    private func populateFromInvite(_ invite: Invite) {
        userID = invite.userID
        type = invite.type
        status = invite.status
        token = invite.token ?? ""
        expiresAt = invite.expiresAt
    }
    
    private func resetForm() {
        userID = UUID()
        type = .invite
        status = .pending
        token = ""
        expiresAt = nil
    }
}
