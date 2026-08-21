//
//  CustomBadgeView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct CustomBadgeView: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    let isCompact: Bool

    init(
        text: String,
        backgroundColor: Color,
        textColor: Color = .white,
        isCompact: Bool = false
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.isCompact = isCompact
    }

    init(
        operatorId: String,
        isCompact: Bool = false
    ) {

        switch operatorId {
        case "KMB":
            self.init(text: "KMB", backgroundColor: .red, isCompact: isCompact)
        case "LWB":
            self.init(
                text: "LWB",
                backgroundColor: Color(red: 0.95, green: 0.45, blue: 0.08),
                isCompact: isCompact
            )
        case "CTB":
            self.init(
                text: "CTB",
                backgroundColor: Color(red: 1, green: 0.82, blue: 0),
                textColor: .black,
                isCompact: isCompact
            )
        case "NLB":
            self.init(
                text: "NLB",
                backgroundColor: Color(red: 0.35, green: 0.75, blue: 0.95),
                textColor: .black,
                isCompact: isCompact
            )
        case "GMB":
            self.init(text: "GMB", backgroundColor: .green, isCompact: isCompact)
        case "LRTFeeder":
            self.init(
                text: "MTR",
                backgroundColor: Color(red: 0.15, green: 0.32, blue: 0.62),
                isCompact: isCompact
            )
        case "PI":
            self.init(text: "PI", backgroundColor: .teal, isCompact: isCompact)
        case "DB":
            self.init(text: "DB", backgroundColor: .purple, isCompact: isCompact)
        case "XB":
            self.init(text: "XB", backgroundColor: .gray, isCompact: isCompact)
        default:
            self.init(text: operatorId, backgroundColor: .gray, isCompact: isCompact)
        }
    }

    var body: some View {
        Text(text)
            .font(
                isCompact
                ? .system(size: 10)
                : .caption
            )
            .fontWeight(.semibold)
            .frame(width: isCompact ? 30 : 35)
            .padding(.horizontal, isCompact ? 8 : 12)
            .padding(.vertical, isCompact ? 4 : 6)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        CustomBadgeView(operatorId: "KMB")
        CustomBadgeView(operatorId: "CTB")
        CustomBadgeView(operatorId: "NLB")
    }
    .padding()
}
