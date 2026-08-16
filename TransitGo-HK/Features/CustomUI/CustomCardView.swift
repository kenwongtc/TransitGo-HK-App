//
//  MessageBubbleView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI
import Combine

struct CustomCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Tracks the active frame from 0 to 4 (representing the 5 steps)
    @State private var currentFrame = 0
    @State var imageIcon: String
    @State var title: String
    @State var subTitle: String
    
    let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        if index == currentFrame {
                            Image(systemName: imageIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                                .frame(width: 30, height: 30)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Circle()
                                .fill(Color.secondary.opacity(0.4))
                                .frame(width: 10, height: 10)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .frame(height: 48)
                .animation(.easeInOut(duration: 0.3), value: currentFrame)
                .onReceive(timer) { _ in
                    // Loop through frames 0 to 4
                    currentFrame = (currentFrame + 1) % 5
                }

                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            .padding(24)
            .frame(width: 300)
            // Pure white for light mode, elevated grey (systemGray6) for dark mode
            .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            .zIndex(1)
        }
    }
}

#Preview {
    CustomCardView(
        imageIcon: "safari",
        title: "Loading",
        subTitle: "Please wait..."
    )
}
