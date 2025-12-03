//
//  DetailsSheetView.swift
//  EventsApp
//
//  Created by Шоу on 11/26/25.
//

import SwiftUI
import UIKit

struct DetailsSheetView: View {
    @Environment(\.theme) private var theme
    
    @State private var localText: String
    
    var onChange: (String) -> Void
    var onDone: () -> Void
    
    private let characterLimit = 140
    
    init(text: String, onChange: @escaping (String) -> Void, onDone: @escaping () -> Void) {
        _localText = State(initialValue: text)
        self.onChange = onChange
        self.onDone = onDone
    }
    
    private var characterCount: Int {
        localText.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                    .foregroundStyle(theme.colors.surface.opacity(0.5))
                
                // Text editor area - takes up available space
                AlignedTextView(
                    text: $localText,
                    placeholder: "What's happening?",
                    theme: theme,
                    characterLimit: characterLimit,
                    onChange: onChange
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom row with progress and Done button
                HStack(spacing: theme.spacing.medium) {
                    CircularProgressView(current: characterCount, limit: characterLimit)
                    
                    Spacer()
                    
                    PrimaryButton(title: "Done") {
                        onDone()
                    }
                }
                .padding(.horizontal, theme.spacing.medium)
                .padding(.bottom, theme.spacing.medium)
            }
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Details")
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
            
            if localText.isEmpty {
                Text("No details yet")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.mainText)
            } else {
                Text(localText)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.mainText)
                    .lineLimit(2)
            }
            
            HStack {
                Spacer()
                Text("\(characterCount)/\(characterLimit)")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.offText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.medium)
        .background(theme.colors.surface.opacity(0.3))
    }
}

// MARK: - Aligned Text View (UITextView wrapper for perfect alignment)

struct AlignedTextView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let theme: AppTheme
    let characterLimit: Int
    let onChange: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 22, weight: .bold) // headline style
        textView.textColor = UIColor(theme.colors.mainText)
        textView.textAlignment = .left
        textView.textContainerInset = UIEdgeInsets(
            top: theme.spacing.medium,
            left: theme.spacing.medium,
            bottom: theme.spacing.medium,
            right: theme.spacing.medium
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.text = text
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        // Update text color based on theme
        uiView.textColor = UIColor(theme.colors.mainText)
        
        // Update placeholder visibility
        context.coordinator.updatePlaceholder(uiView, isEmpty: text.isEmpty)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AlignedTextView
        private var placeholderLabel: UILabel?
        
        init(_ parent: AlignedTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            let newText = textView.text ?? ""
            
            // Enforce character limit
            if newText.count > parent.characterLimit {
                let truncated = String(newText.prefix(parent.characterLimit))
                textView.text = truncated
                parent.text = truncated
                parent.onChange(truncated)
            } else {
                parent.text = newText
                parent.onChange(newText)
            }
            
            updatePlaceholder(textView, isEmpty: textView.text.isEmpty)
        }
        
        func updatePlaceholder(_ textView: UITextView, isEmpty: Bool) {
            if placeholderLabel == nil {
                let label = UILabel()
                label.text = parent.placeholder
                label.font = UIFont.systemFont(ofSize: 22, weight: .bold) // headline style
                label.textColor = UIColor(parent.theme.colors.offText)
                label.textAlignment = .left
                label.numberOfLines = 0
                textView.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                
                // Match exact padding from textContainerInset
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: textView.topAnchor, constant: parent.theme.spacing.medium),
                    label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: parent.theme.spacing.medium),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -parent.theme.spacing.medium)
                ])
                placeholderLabel = label
            }
            
            placeholderLabel?.isHidden = !isEmpty
        }
    }
}
