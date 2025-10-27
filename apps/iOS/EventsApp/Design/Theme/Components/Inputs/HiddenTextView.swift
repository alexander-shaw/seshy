//
//  HiddenTextView.swift
//  EventsApp
//
//  Created by Шоу on 10/21/25.
//

// HiddenTextView.swift

import SwiftUI
import UIKit

final class CaretTextView: UITextView {
    var onTextChange: ((String) -> Void)?
    var onSelectionChange: ((NSRange) -> Void)?

    override var selectedRange: NSRange {
        didSet { onSelectionChange?(selectedRange) }
    }
    override var text: String! {
        didSet { onTextChange?(text ?? "") }
    }
}

struct HiddenTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    var configuration: (CaretTextView) -> Void = { _ in }

    func makeUIView(context: Context) -> CaretTextView {
        let tv = CaretTextView()
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.autocorrectionType = .yes
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.spellCheckingType = .yes
        tv.keyboardType = .default
        tv.returnKeyType = .default
        tv.text = text

        tv.onTextChange = { newText in
            if newText != text { text = newText }
        }
        tv.onSelectionChange = { newRange in
            if newRange != selection { selection = newRange }
        }

        configuration(tv)
        return tv
    }

    func updateUIView(_ uiView: CaretTextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        if uiView.selectedRange != selection {
            uiView.selectedRange = selection
            uiView.scrollRangeToVisible(selection)
        }
    }
}
