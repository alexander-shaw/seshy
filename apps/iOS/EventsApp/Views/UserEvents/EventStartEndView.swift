//
//  EventStartEndView.swift
//  EventsApp
//
//  Created by Шоу on 10/27/25.
//

import SwiftUI
import UIKit

struct EventStartEndView: View {
    @Environment(\.theme) private var theme

    @Binding var startTime: Date?
    @Binding var endTime: Date?
    @Binding var durationMinutes: Int64?
    @Binding var isAllDay: Bool

    // Local state for non-nil date handling.
    @State private var internalStartDate: Date = Date()
    @State private var internalStartTime: Date = Date()
    @State private var internalEndDate: Date = Date()
    @State private var internalEndTime: Date = Date()
    
    // Collapsible state for inline pickers.
    @State private var expandedStartDate: Bool = false
    @State private var expandedStartTime: Bool = false
    @State private var expandedEndDate: Bool = false
    @State private var expandedEndTime: Bool = false
    
    // Track if user is currently adjusting end time to allow manual override.
    @State private var isUserAdjustingEnd: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - ALL DAY TOGGLE:
            HStack {
                Text("ALL DAY")
                    .captionTitleStyle()
                
                Spacer()
                
                Toggle("", isOn: $isAllDay)
                    .labelsHidden()
                    .tint(theme.colors.accent)
            }
            .padding(.horizontal, theme.spacing.medium)
            .frame(minHeight: theme.sizes.iconButton)

            Divider()
                .foregroundStyle(theme.colors.surface)
            
            // MARK: - STARTS:
            DateTimePickerRow(
                title: "Starts",
                date: $internalStartDate,
                time: $internalStartTime,
                expandedDate: $expandedStartDate,
                expandedTime: $expandedStartTime,
                dateFormat: formattedStartDate,
                timeFormat: formattedStartTime,
                onDateChange: { updateStartTime(dateComponent: $0) },
                onTimeChange: { updateStartTime(timeComponent: $0) },
                showTimeFields: !isAllDay
            )
            .frame(minHeight: theme.sizes.iconButton)

            Divider()
                .foregroundStyle(theme.colors.surface)

            // MARK: - ENDS:
            // Shown when start time is set:
            if startTime != nil {
                DateTimePickerRow(
                    title: "Ends",
                    date: $internalEndDate,
                    time: $internalEndTime,
                    expandedDate: $expandedEndDate,
                    expandedTime: $expandedEndTime,
                    dateFormat: formattedEndDate,
                    timeFormat: formattedEndTime,
                    onDateChange: { 
                        isUserAdjustingEnd = true
                        updateEndTime(dateComponent: $0) 
                        isUserAdjustingEnd = false
                    },
                    onTimeChange: { 
                        isUserAdjustingEnd = true
                        updateEndTime(timeComponent: $0) 
                        isUserAdjustingEnd = false
                    },
                    showTimeFields: !isAllDay
                )
                .frame(minHeight: theme.sizes.iconButton)
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: expandedStartDate) { _, _ in
            if expandedStartDate {
                expandedEndDate = false
                expandedEndTime = false
                expandedStartTime = false
            }
        }
        .onChange(of: expandedStartTime) { _, _ in
            if expandedStartTime {
                expandedEndDate = false
                expandedEndTime = false
                expandedStartDate = false
            }
        }
        .onChange(of: expandedEndDate) { _, _ in
            if expandedEndDate {
                expandedStartDate = false
                expandedStartTime = false
                expandedEndTime = false
            }
        }
        .onChange(of: expandedEndTime) { _, _ in
            if expandedEndTime {
                expandedStartDate = false
                expandedStartTime = false
                expandedEndDate = false
            }
        }
        .onAppear {
            initializeDates()
        }
    }
    
    // MARK: - FORMATTED VALUES:
    
    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: internalStartDate)
    }
    
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: internalStartTime)
    }
    
    private var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: internalEndDate)
    }
    
    private var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: internalEndTime)
    }
    
    // MARK: - HELPER METHODS:
    private func initializeDates() {
        if let existingStart = startTime {
            internalStartDate = existingStart
            internalStartTime = existingStart
        } else {
            // Default to current date/time, rounded up to the next hour.
            let now = Date()
            let calendar = Calendar.current
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            internalStartDate = nextHour
            internalStartTime = nextHour
            updateStartTime()
        }
        
        if let existingEnd = endTime {
            internalEndDate = existingEnd
            internalEndTime = existingEnd
        } else if startTime != nil {
            // Default end time to start time + 2 hours.
            let defaultEnd = Calendar.current.date(byAdding: .hour, value: 2, to: startTime ?? Date())
            internalEndDate = defaultEnd ?? Date()
            internalEndTime = defaultEnd ?? Date()
        }
    }
    
    private func updateStartTime(dateComponent: Date? = nil, timeComponent: Date? = nil) {
        let calendar = Calendar.current
        
        // Get the date components from the date picker.
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: internalStartDate)
        
        // Get the time components from the time picker.
        let timeComponents = calendar.dateComponents([.hour, .minute], from: internalStartTime)
        
        // Combine date and time.
        var combinedComponents = dateComponents
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        if let combinedDate = calendar.date(from: combinedComponents) {
            startTime = combinedDate
            
            // Only auto-adjust end time if user is NOT manually adjusting it
            // and if end time is before or equal to start time
            if let currentEnd = endTime, !isUserAdjustingEnd {
                if currentEnd <= combinedDate {
                    // Auto-adjust: add 2 hours to start time
                    let newEnd = calendar.date(byAdding: .hour, value: 2, to: combinedDate) ?? combinedDate
                    endTime = newEnd
                    internalEndDate = newEnd
                    internalEndTime = newEnd
                }
            }
        }
    }
    
    private func updateEndTime(dateComponent: Date? = nil, timeComponent: Date? = nil) {
        let calendar = Calendar.current
        
        // Get the date components from the date picker.
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: internalEndDate)
        
        // Get the time components from the time picker.
        let timeComponents = calendar.dateComponents([.hour, .minute], from: internalEndTime)
        
        // Combine date and time.
        var combinedComponents = dateComponents
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        if let combinedDate = calendar.date(from: combinedComponents) {
            // Allow user to set end time before start if they're manually adjusting.
            // Only auto-adjust if user changes start time and end becomes invalid.
            endTime = combinedDate
            
            // Recalculate duration when end time changes.
            if let start = startTime {
                let duration = Int64(combinedDate.timeIntervalSince(start) / 60)
                durationMinutes = duration  // Allow negative durations if user explicitly sets it.
            }
        }
    }
}

// MARK: DateTimePickerRow Component:
private struct DateTimePickerRow: View {
    @Environment(\.theme) private var theme
    
    let title: String
    @Binding var date: Date
    @Binding var time: Date
    @Binding var expandedDate: Bool
    @Binding var expandedTime: Bool

    let dateFormat: String
    let timeFormat: String
    let onDateChange: (Date) -> Void
    let onTimeChange: (Date) -> Void
    let showTimeFields: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row with the date and time components side by side.
            HStack(spacing: theme.spacing.small) {
                Text(title)
                    .captionTitleStyle()
                
                Spacer()
                
                // Date field.
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        expandedDate.toggle()
                        expandedTime = false
                    }
                }) {
                    Text(dateFormat)
                        .captionTitleStyle()
                        // .padding(.vertical, theme.spacing.small / 2)
                        // .padding(.horizontal, theme.spacing.small)
                        // .background(expandedDate ? theme.colors.background : Color.clear)
                        // .cornerRadius(6)
                }
                .hapticFeedback(.soft)

                // Time field (shown only when showTimeFields is true).
                if showTimeFields {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            expandedTime.toggle()
                            expandedDate = false
                        }
                    }) {
                        Text(timeFormat)
                            .captionTitleStyle()
                            // .padding(.vertical, theme.spacing.small / 2)
                            // .padding(.horizontal, theme.spacing.small)
                            // .background(expandedTime ? theme.colors.background : Color.clear)
                            // .cornerRadius(6)
                    }
                    .hapticFeedback(.soft)
                }
            }
            .padding(.vertical, theme.spacing.small)
            .padding(.horizontal, theme.spacing.medium)
            
            // Inline Pickers (Expandable).
            if expandedDate {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal, theme.spacing.small)
                .padding(.bottom, theme.spacing.small)
                .onChange(of: date) { _, newDate in
                    onDateChange(newDate)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if expandedTime && showTimeFields {
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .frame(height: 180)
                .onChange(of: time) { _, newTime in
                    onTimeChange(newTime)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
