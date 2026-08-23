//
//  CustomRouteBannerView.swift
//  TransitGo-HK
//

import SwiftUI

struct CustomRouteBannerView: View {
    let origin: String
    let destination: String

    var body: some View {
        VStack(
            alignment: .center,
            spacing: 8
        ) {
            Text(origin)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("to")
                .foregroundStyle(.secondary)


            Text(destination)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
        .customInfoCardSurface(
            showsShadow: false
        )
    }
}

#Preview {
    CustomRouteBannerView(
        origin: "Greenfield Garden",
        destination: "Tin Hau Station"
    )
    .padding()
}
