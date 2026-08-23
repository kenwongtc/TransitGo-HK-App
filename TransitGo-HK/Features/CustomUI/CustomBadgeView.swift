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
    let fontSize: CGFloat?

    init(
        text: String,
        backgroundColor: Color,
        textColor: Color = .white,
        isCompact: Bool = false,
        fontSize: CGFloat? = nil
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.isCompact = isCompact
        self.fontSize = fontSize
    }

    init(
        operatorId: String,
        isCompact: Bool = false,
        fontSize: CGFloat? = nil
    ) {
        self.init(
            text: Self.displayText(
                for: operatorId
            ),
            backgroundColor:
                Self.backgroundColor(
                    for: operatorId
                ),
            textColor: Self.textColor(
                for: operatorId
            ),
            isCompact: isCompact,
            fontSize: fontSize
        )
    }

    static func displayText(
        for operatorId: String
    ) -> String {
        operatorId == "LRTFeeder"
            ? "MTR"
            : operatorId
    }

    static func backgroundColor(
        for operatorId: String
    ) -> Color {
        switch operatorId {
        case "KMB":
            .red
        case "LWB":
            Color(
                red: 0.95,
                green: 0.45,
                blue: 0.08
            )
        case "CTB":
            Color(
                red: 1,
                green: 0.82,
                blue: 0
            )
        case "NLB":
            Color(
                red: 0.35,
                green: 0.75,
                blue: 0.95
            )
        case "GMB":
            .green
        case "LRTFeeder":
            Color(
                red: 0.15,
                green: 0.32,
                blue: 0.62
            )
        case "PI":
            .teal
        case "DB":
            .purple
        case "XB":
            .gray
        default:
            .gray
        }
    }

    static func textColor(
        for operatorId: String
    ) -> Color {
        switch operatorId {
        case "CTB", "NLB":
            .black
        default:
            .white
        }
    }

    private var badgeFont: Font {
        if let fontSize {
            return .system(size: fontSize)
        }

        return isCompact
            ? .system(size: 10)
            : .caption
    }

    var body: some View {
        Text(text)
            .font(badgeFont)
            .fontWeight(.semibold)
            .frame(minWidth: isCompact ? 30 : 35)
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
