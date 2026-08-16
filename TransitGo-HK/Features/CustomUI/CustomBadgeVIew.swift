//
//  CustomBadgeVIew.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct CustomBadgeView: View {
    var text: String
    var backgroundColor: Color
    var textColor: Color = .white

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .frame(width: 35)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        CustomBadgeView(text: "KMB", backgroundColor: .green)
    }
    .padding()
}
