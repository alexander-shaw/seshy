//
//  DateTimeSheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI

struct DateTimeSheetView: View {
    var startTime: Date?
    var endTime: Date?
    var durationMinutes: Int?
    var isAllDay: Bool
    var calendar: Calendar
    var onChange: (EventTimeSnapshot, EventTimeMode) -> Void
    var onDone: () -> Void

    @State private var localStartTime: Date
    @State private var localEndTime: Date
    @State private var localDurationMinutes: Int?
    @State private var mode: EventTimeMode
    @State private var useEndTime: Bool = false

    @Environment(\.theme) private var theme

    init(
        startTime: Date?,
        endTime: Date?,
        durationMinutes: Int?,
        isAllDay: Bool,
        calendar: Calendar = .current,
        onChange: @escaping (EventTimeSnapshot, EventTimeMode) -> Void,
        onDone: @escaping () -> Void
    ) {
        // Initialize all stored properties first
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isAllDay = isAllDay
        self.calendar = calendar
        self.onChange = onChange
        self.onDone = onDone

        // Always set a default start time - required for events
        let cal = calendar
        let startValue = startTime ?? Date()
        let roundedStart = DateTimeSheetView.roundToNearest15Minutes(startValue, calendar: cal)
        let defaultEnd = endTime ?? cal.date(byAdding: .hour, value: 2, to: roundedStart) ?? roundedStart
        let roundedEnd = DateTimeSheetView.roundToNearest15Minutes(defaultEnd, calendar: cal)
        _localStartTime = State(initialValue: roundedStart)
        _localEndTime = State(initialValue: roundedEnd)
        // Default to nil - user can choose to set duration or end time if they want
        _localDurationMinutes = State(initialValue: durationMinutes)
        
        // Infer mode: default to duration if no explicit end time
        let inferredMode: EventTimeMode
        if isAllDay {
            inferredMode = .allDay
        } else if endTime != nil {
            inferredMode = .end
        } else {
            inferredMode = .duration
        }
        _mode = State(initialValue: inferredMode)
        _useEndTime = State(initialValue: endTime != nil)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                    .foregroundStyle(theme.colors.surface)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.large) {
                        // All Day Toggle
                        allDayToggleSection
                        
                        if mode != .allDay {
                            // Date Section
                            dateSection
                            
                            // Time Section
                            timeSection
                            
                            // End Time or Duration Section
                            endTimeOrDurationSection
                        }
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Date & Time")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
        .onChange(of: localStartTime) { _, newValue in
            let rounded = roundToNearest15Minutes(newValue, calendar: calendar)
            if rounded != newValue {
                localStartTime = rounded
            } else {
                sendChange()
            }
        }
        .onChange(of: localEndTime) { _, newValue in
            let rounded = roundToNearest15Minutes(newValue, calendar: calendar)
            if rounded != newValue {
                localEndTime = rounded
            } else {
                sendChange()
            }
        }
        .onChange(of: useEndTime) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = newValue ? .end : .duration
                handleModeChange(mode)
            }
        }
        .onAppear {
            sendChange()
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
        if mode == .allDay {
            return EventDateTimeFormatter.composerSummary(
                start: localStartTime,
                end: nil,
                durationMinutes: nil,
                isAllDay: true,
                calendar: calendar
            )
        }
        
        if mode == .end {
            return EventDateTimeFormatter.composerSummary(
                start: localStartTime,
                end: localEndTime,
                durationMinutes: nil,
                isAllDay: false,
                calendar: calendar
            )
        }
        
        // Duration mode - may be nil (no duration selected)
        return EventDateTimeFormatter.composerSummary(
            start: localStartTime,
            end: nil,
            durationMinutes: localDurationMinutes.map { Int64($0) },
            isAllDay: false,
            calendar: calendar
        )
    }
    
    // MARK: - All Day Toggle
    
    private var allDayToggleSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Toggle(isOn: Binding(
                get: { mode == .allDay },
                set: { isOn in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mode = isOn ? .allDay : (useEndTime ? .end : .duration)
                        handleModeChange(mode)
                    }
                }
            )) {
                Text("All Day Event")
                    .bodyTextStyle()
            }
            .toggleStyle(SwitchToggleStyle(tint: theme.colors.accent))
        }
        .padding(.vertical, theme.spacing.small)
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Date")
            
            DatePicker(
                "",
                selection: $localStartTime,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.graphical)
        }
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            sectionHeader("Start Time")
            
            DatePicker(
                "",
                selection: $localStartTime,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
        }
    }
    
    // MARK: - End Time or Duration Section
    
    private var endTimeOrDurationSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            // Toggle between End Time and Duration
            HStack {
                sectionHeader("End Time")
                Spacer()
                Picker("", selection: $useEndTime) {
                    Text("Duration").tag(false)
                    Text("End Time").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            if useEndTime {
                // End Time Pickers
                VStack(spacing: theme.spacing.medium) {
                    DatePicker(
                        "",
                        selection: $localEndTime,
                        in: localStartTime...,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    
                    DatePicker(
                        "",
                        selection: $localEndTime,
                        in: localStartTime...,
                        displayedComponents: [.hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                }
            } else {
                // Duration Picker
                durationPicker
            }
        }
    }
    
    // MARK: - Duration Picker
    
    private var durationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.small) {
                ForEach(durationOptions, id: \.minutes) { option in
                    durationButton(option: option)
                }
            }
            .padding(.horizontal, theme.spacing.small)
        }
    }
    
    private func durationButton(option: DurationOption) -> some View {
        let isSelected = localDurationMinutes == option.minutes
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                // Toggle: if already selected, deselect (set to nil)
                if isSelected {
                    localDurationMinutes = nil
                } else {
                    localDurationMinutes = option.minutes
                }
                sendChange()
            }
        } label: {
            Text(option.label)
                .font(theme.typography.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(
                    isSelected
                        ? theme.colors.mainText
                        : theme.colors.offText
                )
                .padding(.horizontal, theme.spacing.medium)
                .padding(.vertical, theme.spacing.small)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? theme.colors.accent.opacity(0.2)
                                : theme.colors.surface.opacity(0.5)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected
                                        ? theme.colors.accent
                                        : theme.colors.surface,
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )
                )
        }
        .buttonStyle(CollapseButtonStyle())
        .hapticFeedback(.light)
    }
    
    private struct DurationOption {
        let minutes: Int
        let label: String
    }
    
    private var durationOptions: [DurationOption] {
        [
            DurationOption(minutes: 30, label: "30m"),
            DurationOption(minutes: 60, label: "1h"),
            DurationOption(minutes: 120, label: "2h"),
            DurationOption(minutes: 180, label: "3h"),
            DurationOption(minutes: 240, label: "4h"),
            DurationOption(minutes: 360, label: "6h"),
            DurationOption(minutes: 480, label: "8h")
        ]
    }
    
    // MARK: - Section Header Helper
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.offText)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    // MARK: - Mode Handling

    private func handleModeChange(_ newMode: EventTimeMode) {
        mode = newMode
        switch newMode {
        case .none:
            break
        case .allDay:
            break
        case .end:
            if localEndTime < localStartTime {
                localEndTime = calendar.date(byAdding: .hour, value: 2, to: localStartTime) ?? localStartTime
            }
        case .duration:
            // Allow nil - user can choose not to set duration
            break
        }
        sendChange()
    }

    private func sendChange() {
        // Start time is always required.
        let snapshot = EventTimeSnapshot(
            start: localStartTime,
            end: mode == .none || mode == .duration ? nil : (mode == .allDay ? nil : localEndTime),
            durationMinutes: mode == .none || mode == .allDay || mode == .end ? nil : localDurationMinutes,
            isAllDay: mode == .allDay
        )
        onChange(snapshot, mode)
    }
    
    private static func roundToNearest15Minutes(_ date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minutes = components.minute ?? 0
        let roundedMinutes = ((minutes + 7) / 15) * 15
        var newComponents = components
        newComponents.minute = roundedMinutes % 60
        if roundedMinutes >= 60 {
            newComponents.hour = (newComponents.hour ?? 0) + 1
        }
        return calendar.date(from: newComponents) ?? date
    }
    
    private func roundToNearest15Minutes(_ date: Date, calendar: Calendar) -> Date {
        Self.roundToNearest15Minutes(date, calendar: calendar)
    }
}
