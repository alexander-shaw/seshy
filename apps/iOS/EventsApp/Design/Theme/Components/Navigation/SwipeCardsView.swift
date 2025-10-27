//
//  SwipeCardsView.swift
//  Invited
//
//  Created by Шоу on 7/8/25.
//

import SwiftUI

struct SwipeCardsView<Step: Hashable & Identifiable, Content: View>: View {
    @Environment(\.theme) private var theme

    @Binding var selectedStep: Step
    let steps: [Step]
    let isStepComplete: (Step) -> Bool
    @ViewBuilder let contentForStep: (Step) -> Content

    var body: some View {
        TabView(selection: $selectedStep) {
            ForEach(steps, id: \.self) { step in
                VStack {
                    contentForStep(step)
                }
                .padding(.horizontal, theme.spacing.medium)  // Better here to avoid black bars.
                .tag(step)
                .contentShape(Rectangle())
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .gesture(
            DragGesture()
                .onEnded { value in
                    let verticalAmount = value.translation.height
                    guard abs(verticalAmount) > 50 else { return }

                    let currentIndex = steps.firstIndex(of: selectedStep) ?? 0
                    let newIndex: Int?

                    if verticalAmount < 0 {
                        newIndex = currentIndex < steps.count - 1 ? currentIndex + 1 : nil
                    } else {
                        newIndex = currentIndex > 0 ? currentIndex - 1 : nil
                    }

                    if let index = newIndex, isStepComplete(selectedStep) {
                        selectedStep = steps[index]
                    }
                }
        )
    }
}
