//
//  TeamSheetView.swift
//  EventsApp
//
//  Created by Auto on 12/6/24.
//

import SwiftUI
import CoreData

struct TeamSheetView: View {
    var eventID: UUID?
    var onDone: () -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var event: EventItem?
    
    private var members: [Member] {
        guard let event = event,
              let membersSet = event.members as? Set<Member> else {
            return []
        }
        return Array(membersSet).sorted { first, second in
            // Sort by role: host first, then staff, then guests
            if first.role != second.role {
                return first.role.rawValue < second.role.rawValue
            }
            // Then by display name
            return first.displayName < second.displayName
        }
    }
    
    private var hosts: [Member] {
        members.filter { $0.role == .host }
    }
    
    private var staff: [Member] {
        members.filter { $0.role == .staff }
    }
    
    private var guests: [Member] {
        members.filter { $0.role == .guest }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                    .foregroundStyle(theme.colors.surface.opacity(0.5))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        if members.isEmpty {
                            emptyState
                        } else {
                            if !hosts.isEmpty {
                                memberSection(title: "Host", members: hosts, icon: "crown.fill")
                            }
                            
                            if !staff.isEmpty {
                                memberSection(title: "Staff", members: staff, icon: "person.badge.shield.checkmark.fill")
                            }
                            
                            if !guests.isEmpty {
                                memberSection(title: "Guests", members: guests, icon: "person.fill")
                            }
                        }
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Team")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
        .task {
            if let eventID = eventID {
                await loadEvent(id: eventID)
            }
        }
    }
    
    // MARK: - Load Event
    
    private func loadEvent(id: UUID) async {
        let repository = CoreEventItemRepository()
        do {
            event = try await repository.getEvent(by: id)
        } catch {
            print("TeamSheetView | Failed to load event: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("Preview")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.offText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(previewText)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.mainText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
    
    private var previewText: String {
        let count = members.count
        if count == 0 {
            return "No team members yet"
        } else if count == 1 {
            return "1 team member"
        } else {
            return "\(count) team members"
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: theme.spacing.medium) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(theme.colors.offText.opacity(0.5))
            
            Text("No team members yet")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.offText)
            
            Text("Team members will appear here once the event is created and people join.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.offText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.large * 2)
    }
    
    // MARK: - Member Section
    
    private func memberSection(title: String, members: [Member], icon: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            HStack(spacing: theme.spacing.small) {
                Image(systemName: icon)
                    .foregroundStyle(theme.colors.accent)
                    .iconStyle()
                
                Text(title)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.offText)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            VStack(spacing: theme.spacing.small) {
                ForEach(members, id: \.id) { member in
                    memberRow(member: member)
                }
            }
        }
    }
    
    // MARK: - Member Row
    
    private func memberRow(member: Member) -> some View {
        HStack(spacing: theme.spacing.medium) {
            // Avatar
            if let avatarURL = member.avatarURL, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(theme.colors.surface)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(theme.colors.surface)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(member.displayName.prefix(1).uppercased())
                            .font(theme.typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.colors.mainText)
                    )
            }
            
            // Name and Username
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.colors.mainText)
                
                if let username = member.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.offText)
                }
            }
            
            Spacer()
        }
        .padding(theme.spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: theme.spacing.medium)
                .fill(theme.colors.surface.opacity(0.3))
        )
    }
}

