//
//  ThemeSheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/27/25.
//

import SwiftUI

struct ThemeSheetView: View {
    @ObservedObject var viewModel: EventViewModel
    var onDone: () -> Void
    
    @State private var expandedRow: ThemeRow?
    @State private var activeTab: ThemePickerTab = .mood

    @Environment(\.theme) private var theme
    
    private var currentThemeColors: ThemePresetHelper.ThemeColors {
        viewModel.currentThemeColors()
    }
    
    private var themeMode: ThemePresetHelper.ThemeMode {
        ThemePresetHelper.ThemeMode(rawValue: viewModel.themeMode) ?? .auto
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
                        // Event Theme Section
                        eventThemeSection
                        
                        Divider()
                            .background(theme.colors.surface.opacity(0.5))
                        
                        // Media List Section (read-only)
                        if viewModel.selectedMediaItems.isEmpty && viewModel.media.isEmpty {
                            Text("Add photos to see their colors.")
                                .foregroundStyle(theme.colors.offText)
                                .font(theme.typography.body)
                                .padding(.vertical, theme.spacing.medium)
                        } else {
                            mediaListSection
                        }
                    }
                    .padding(theme.spacing.medium)
                }
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Theme")
                        .font(theme.typography.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
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
            
            HStack(spacing: theme.spacing.medium) {
                // Color preview circle with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: currentThemeColors.primaryHex) ?? theme.colors.surface,
                                    Color(hex: currentThemeColors.secondaryHex) ?? theme.colors.surface
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.surface.opacity(0.5), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(themeInfoText)
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.mainText)
                    
                    Text(themeMode.rawValue.capitalized)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.offText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
    
    // MARK: - Event Theme Section
    
    private var eventThemeSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            // Theme Preview
            HStack(spacing: theme.spacing.medium) {
                // Color preview circle with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: currentThemeColors.primaryHex) ?? theme.colors.surface,
                                    Color(hex: currentThemeColors.secondaryHex) ?? theme.colors.surface
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.surface.opacity(0.5), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Theme")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.mainText)
                    
                    Text(themeInfoText)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.offText)
                }
                
                Spacer()
            }
            
            // Preset Chips
            HStack(spacing: theme.spacing.small) {
                ForEach(ThemePresetHelper.ThemeMode.allCases, id: \.self) { mode in
                    ThemePresetChip(
                        mode: mode,
                        isSelected: themeMode == mode,
                        onTap: {
                            viewModel.applyThemeMode(mode)
                        }
                    )
                }
            }
            
            // Theme Picker (if expanded)
            if expandedRow == .event {
                ThemePickerInline(
                    contextID: ThemeRow.event.id,
                    activeTab: $activeTab,
                    allowGradients: true,
                    currentValue: ThemeColorValue.solid(hex: currentThemeColors.primaryHex),
                    onSelect: { value in
                        let encoded = ThemeColorParser.encode(value)
                        if case .solid(let hex) = value {
                            viewModel.themePrimaryHex = hex
                            viewModel.themeSecondaryHex = hex
                            viewModel.themeMode = ThemePresetHelper.ThemeMode.custom.rawValue
                        }
                    },
                    onClose: { expandedRow = nil }
                )
            }
        }
    }
    
    private var themeInfoText: String {
        let primaryHex = currentThemeColors.primaryHex.uppercased()
        let modeName = themeMode.displayName
        
        if themeMode == .auto {
            if let coverMedia = viewModel.selectedMediaItems.first(where: { $0.mediaKind == .image }) {
                return "\(primaryHex) · From cover photo"
            } else if let firstMedia = viewModel.media.first {
                return "\(primaryHex) · From cover photo"
            } else {
                return "\(primaryHex) · \(modeName)"
            }
        } else {
            return "\(primaryHex) · \(modeName)"
        }
    }
    
    // MARK: - Media List Section
    
    private var mediaListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text("Media")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.mainText)
                .padding(.bottom, theme.spacing.small)
            
            ForEach(mediaItems) { item in
                mediaRow(for: item)
            }
        }
    }
    
    private var mediaItems: [MediaItem] {
        // Combine selectedMediaItems and existing media
        var items: [MediaItem] = []
        items.append(contentsOf: viewModel.selectedMediaItems)
        // Note: We can't easily convert Media to MediaItem, so for now just show selectedMediaItems
        // In a real implementation, you'd want to convert Media to MediaItem for display
        return items
    }
    
    private func mediaRow(for item: MediaItem) -> some View {
        let mediaIndex = max(1, Int(item.position) + 1)
        let isCoverMedia = item.position == 0
        
        return HStack(spacing: theme.spacing.medium) {
            // Thumbnail
            if let thumbnail = item.uiImage() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.colors.surface)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: theme.spacing.small) {
                    Text("Media \(mediaIndex)")
                        .font(theme.typography.body)
                    if isCoverMedia {
                        Text("(Cover)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.accent)
                    }
                }
                
                // Color dots (read-only)
                HStack(spacing: 6) {
                    if let primaryHex = item.primaryColorHex {
                        Circle()
                            .fill(Color(hex: primaryHex) ?? theme.colors.surface)
                            .frame(width: 12, height: 12)
                    }
                    if let secondaryHex = item.secondaryColorHex, secondaryHex != item.primaryColorHex {
                        Circle()
                            .fill(Color(hex: secondaryHex) ?? theme.colors.surface)
                            .frame(width: 12, height: 12)
                    }
                    if item.primaryColorHex == nil && item.secondaryColorHex == nil {
                        Text("No colors")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.offText)
                    }
                }
            }
            
            Spacer()
            
            // "Use as cover" button (only if not already cover)
            if !isCoverMedia {
                Button {
                    viewModel.setCoverMedia(item)
                } label: {
                    Text("Set Cover")
                        .font(theme.typography.caption)
                        .padding(.horizontal, theme.spacing.small)
                        .padding(.vertical, 6)
                        .background(theme.colors.surface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, theme.spacing.small)
    }
}

// MARK: - Theme Preset Chip

private struct ThemePresetChip: View {
    let mode: ThemePresetHelper.ThemeMode
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            Text(mode.displayName)
                .font(theme.typography.caption)
                .padding(.horizontal, theme.spacing.small)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.colors.accent : theme.colors.surface)
                        .overlay(
                            Capsule()
                                .stroke(theme.colors.surface.opacity(0.6), lineWidth: 1)
                        )
                )
                .foregroundStyle(isSelected ? .white : theme.colors.mainText)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Picker Inline (reused from original)

private struct ThemePickerInline: View {
    let contextID: String
    @Binding var activeTab: ThemePickerTab
    let allowGradients: Bool
    let currentValue: ThemeColorValue?
    let onSelect: (ThemeColorValue) -> Void
    let onClose: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var hexInput: String = ThemeColorLibrary.defaultSwatches.first ?? "#FFFFFF"
    @State private var gradientStops: [String] = ThemeColorLibrary.defaultGradientStops
    @State private var selectedGradientStop: Int = 0
    @State private var gradientAngleIndex: Int = 0
    @State private var lastAppliedContextID: String = ""
    @State private var lastAppliedEncodedValue: String = ""
    
    private var encodedValue: String {
        guard let currentValue else { return "" }
        return ThemeColorParser.encode(currentValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            HStack {
                ThemePickerTabBar(activeTab: $activeTab, allowGradients: allowGradients)
                Spacer()
                IconButton(icon: "chevron.down", style: .secondary) {
                    onClose()
                }
            }
            
            switch activeTab {
            case .mood:
                MoodPresetSection(selectedValue: currentValue, onSelect: onSelect)
            case .gradient:
                gradientBuilderSection
            case .pure:
                pureColorSection
            }
        }
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            syncState(force: true)
        }
        .onChange(of: contextID) { _ in
            syncState(force: true)
        }
        .onChange(of: encodedValue) { _ in
            syncState(force: false)
        }
    }
    
    private var gradientBuilderSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            HStack {
                Text("Stops")
                    .font(theme.typography.caption)
                Spacer()
                Button {
                    addGradientStop()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(gradientStops.count >= 3)
                
                Button {
                    removeGradientStop()
                } label: {
                    Image(systemName: "minus.circle")
                }
                .disabled(gradientStops.count <= 2)
            }
            .foregroundStyle(theme.colors.offText)
            
            HStack(spacing: theme.spacing.small) {
                ForEach(Array(gradientStops.enumerated()), id: \.offset) { index, stop in
                    ColorSwatchButton(
                        value: .solid(hex: stop),
                        fallbackValue: nil,
                        isActive: index == selectedGradientStop,
                        showsPlusWhenEmpty: false,
                        action: { selectedGradientStop = index }
                    )
                }
            }
            
            ColorSwatchGrid(
                colors: ThemeColorLibrary.defaultSwatches,
                selectedColor: gradientStops[selectedGradientStop],
                onSelect: { hex in
                    updateGradientStop(at: selectedGradientStop, with: hex)
                }
            )
            
            HStack {
                Button {
                    advanceGradientAngle()
                } label: {
                    Label("\(Int(ThemeColorLibrary.gradientAngles[gradientAngleIndex]))°", systemImage: "arrow.clockwise.circle")
                }
                
                Spacer()
                
                Button("Apply Gradient") {
                    let value = ThemeColorValue.linearGradient(
                        angle: ThemeColorLibrary.gradientAngles[gradientAngleIndex],
                        stops: gradientStops
                    )
                    onSelect(value)
                }
                .buttonStyle(CollapseButtonStyle())
            }
        }
    }
    
    private var pureColorSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            ColorSwatchGrid(
                colors: ThemeColorLibrary.defaultSwatches,
                selectedColor: ThemeColorParser.sanitizedHex(hexInput),
                onSelect: { hex in
                    hexInput = hex
                    onSelect(.solid(hex: hex))
                }
            )
            
            HStack {
                TextField("#RRGGBB", text: $hexInput)
                    .textInputAutocapitalization(.characters)
                    .font(theme.typography.caption)
                    .textFieldStyle(.roundedBorder)
                
                Button("Apply") {
                    let normalized = ThemeColorParser.sanitizedHex(hexInput)
                    hexInput = normalized
                    onSelect(.solid(hex: normalized))
                }
            }
        }
    }
    
    private func syncState(force: Bool) {
        let encoded = encodedValue
        guard force || lastAppliedContextID != contextID || lastAppliedEncodedValue != encoded else { return }
        lastAppliedContextID = contextID
        lastAppliedEncodedValue = encoded
        
        if let currentValue {
            switch currentValue {
            case .solid(let hex):
                hexInput = hex
                gradientStops = ThemeColorLibrary.defaultGradientStops
                gradientAngleIndex = 0
                selectedGradientStop = 0
            case .linearGradient(let angle, let stops):
                hexInput = stops.first ?? (ThemeColorLibrary.defaultSwatches.first ?? "#FFFFFF")
                gradientStops = stops
                gradientAngleIndex = ThemeColorLibrary.gradientAngles.firstIndex(of: angle) ?? 0
                selectedGradientStop = 0
            }
        } else {
            hexInput = ThemeColorLibrary.defaultSwatches.first ?? "#FFFFFF"
            gradientStops = ThemeColorLibrary.defaultGradientStops
            gradientAngleIndex = 0
            selectedGradientStop = 0
        }
    }
    
    private func addGradientStop() {
        guard gradientStops.count < 3 else { return }
        gradientStops.append(gradientStops.last ?? hexInput)
    }
    
    private func removeGradientStop() {
        guard gradientStops.count > 2 else { return }
        gradientStops.removeLast()
        selectedGradientStop = min(selectedGradientStop, gradientStops.count - 1)
    }
    
    private func updateGradientStop(at index: Int, with hex: String) {
        guard gradientStops.indices.contains(index) else { return }
        gradientStops[index] = hex
    }
    
    private func advanceGradientAngle() {
        gradientAngleIndex = (gradientAngleIndex + 1) % ThemeColorLibrary.gradientAngles.count
    }
}

// MARK: - Supporting Views (reused from original)

private struct ColorSwatchButton: View {
    @Environment(\.theme) private var theme
    
    let value: ThemeColorValue?
    let fallbackValue: ThemeColorValue?
    let isActive: Bool
    let showsPlusWhenEmpty: Bool
    let action: () -> Void
    
    private var displayValue: ThemeColorValue? {
        value ?? fallbackValue
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fillStyle)
                    .frame(width: theme.sizes.iconButton, height: theme.sizes.iconButton)
                    .overlay(
                        Circle()
                            .stroke(isActive ? theme.colors.accent : theme.colors.surface.opacity(0.5), lineWidth: isActive ? 3 : 1)
                    )
                
                if value == nil && showsPlusWhenEmpty {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.colors.mainText)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var fillStyle: AnyShapeStyle {
        guard let displayValue else {
            return AnyShapeStyle(theme.colors.surface.opacity(0.2))
        }
        
        switch displayValue {
        case .solid(let hex):
            return AnyShapeStyle(Color(hex: hex) ?? theme.colors.surface)
        case .linearGradient(_, let stops):
            let colors = stops.compactMap { Color(hex: $0) }
            if colors.isEmpty {
                return AnyShapeStyle(theme.colors.surface)
            }
            let gradient = LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            return AnyShapeStyle(gradient)
        }
    }
}

private struct MoodPresetSection: View {
    let selectedValue: ThemeColorValue?
    let onSelect: (ThemeColorValue) -> Void
    
    private var selectedEncoded: String {
        guard let selectedValue else { return "" }
        return ThemeColorParser.encode(selectedValue)
    }
    
    var body: some View {
        WrapAroundLayout {
            ForEach(ThemeColorLibrary.moodPresets) { preset in
                let encoded = ThemeColorParser.encode(preset.value)
                VibeCapsule(
                    title: preset.name,
                    isSelected: encoded == selectedEncoded,
                    onTap: { onSelect(preset.value) }
                )
            }
        }
    }
}

private struct ColorSwatchGrid: View {
    let colors: [String]
    let selectedColor: String?
    let onSelect: (String) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(colors, id: \.self) { hex in
                let normalized = ThemeColorParser.sanitizedHex(hex)
                ColorSwatchButton(
                    value: .solid(hex: normalized),
                    fallbackValue: nil,
                    isActive: normalized == selectedColor,
                    showsPlusWhenEmpty: false,
                    action: { onSelect(normalized) }
                )
            }
        }
    }
}

private struct ThemePickerTabBar: View {
    @Environment(\.theme) private var theme
    @Binding var activeTab: ThemePickerTab
    let allowGradients: Bool
    
    private var tabs: [ThemePickerTab] {
        allowGradients ? ThemePickerTab.allCases : ThemePickerTab.allCases.filter { $0 != .gradient }
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.small) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    Text(tab.title)
                        .font(theme.typography.caption)
                        .padding(.horizontal, theme.spacing.small)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(activeTab == tab ? theme.colors.surface : .clear)
                                .overlay(
                                    Capsule()
                                        .stroke(theme.colors.surface.opacity(0.6), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Helpers

private enum ThemeRow: Equatable {
    case event
    case media(UUID)
    
    var id: String {
        switch self {
        case .event:
            return "event"
        case .media(let id):
            return "media-\(id.uuidString)"
        }
    }
}

private enum ThemePickerTab: String, CaseIterable {
    case mood
    case gradient
    case pure
    
    var title: String {
        switch self {
        case .mood: return "Mood Presets"
        case .gradient: return "Gradient"
        case .pure: return "Pure Color"
        }
    }
}
