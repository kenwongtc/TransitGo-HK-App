//
//  CustomRouteDetailedBanner.swift
//  TransitGo-HK
//

import SwiftUI

struct CustomRouteDetailedBanner: View {
    let routeNumber: String
    let origin: String
    let destination: String

    private var routeNumberWidth: CGFloat {
        min(
            max(
                CGFloat(routeNumber.count) * 20,
                40
            ),
            84
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(routeNumber)
                .font(.system(size: 28, weight: .semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(width: routeNumberWidth)
                .frame(
                    maxHeight: .infinity,
                    alignment: .center
                )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text("Goes between")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(origin)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(destination)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .leading
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 100)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .customInfoCardSurface()
    }
}

#Preview {
    CustomRouteDetailedBanner(
        routeNumber: "948B",
        origin: "Greenfield Garden",
        destination: "Causeway Bay (Tin Hau)"
    )
    .padding()
    .background(.orange.opacity(0.12))
}
