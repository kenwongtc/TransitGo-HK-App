//
//  CustomInfoCardView.swift
//  TransitGo-HK
//
//  Created by Ken on 22/8/2026.
//

import SwiftUI

struct CustomInfoCardView<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height * 0.15,
                        maxHeight: geometry.size.height * 0.15,
                        alignment: .top
                    )

                content
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height * 0.85,
                        maxHeight: geometry.size.height * 0.85,
                        alignment: .center
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .customInfoCardSurface()
    }
}

extension CustomInfoCardView where Content == Text {
    init(title: String, message: String) {
        self.init(title: title) {
            Text(message)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    CustomInfoCardView(
        title: "Route Number",
        message: "1"
    )
}
