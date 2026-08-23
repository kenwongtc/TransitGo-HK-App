//
//  JourneySummaryView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI

struct JourneySummaryView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    let journey: JourneyEntity
    let isCircular: Bool
    let circularDestination: String

    private var orderedStops: [JourneyStopEntity] {
        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    var body: some View {

        HStack(spacing: 12) {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(
                        orderedStops.last?
                            .stop?
                            .displayName(for: transitLanguage)
                        ?? "Destination unavailable"
                    )
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                HStack(spacing: 8) {
                    Text(lowerEndpointText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("\(orderedStops.count) stops")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(
            .vertical,
            6
        )
    }

    private var lowerEndpointText: String {
        orderedStops.first?
            .stop?
            .displayName(for: transitLanguage)
            ?? (isCircular
                ? circularDestination
                : "Origin unavailable")
    }
}
