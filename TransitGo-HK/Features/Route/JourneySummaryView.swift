//
//  JourneySummaryView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI

struct JourneySummaryView: View {

    let journey: JourneyEntity
    let isCircular: Bool
    let circularDestination: String

    private var orderedStops: [JourneyStopEntity] {
        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            if let origin =
                journey.originStop {

                Text(
                    origin.displayNameEnglish
                )
                .font(.headline)

            } else {

                Text("Origin unavailable")
                    .foregroundStyle(.secondary)
            }

            if isCircular {

                HStack(spacing: 8) {

                    Image(
                        systemName:
                            "arrow.trianglehead.2.clockwise"
                    )
                    .foregroundStyle(.secondary)

                    Text(
                        "Circular via \(circularDestination)"
                    )
                    .foregroundStyle(.secondary)
                }

            } else {

                HStack(spacing: 8) {

                    Image(
                        systemName:
                            "arrow.down"
                    )
                    .foregroundStyle(.secondary)

                    Text("to")
                        .foregroundStyle(.secondary)
                }

                if let destination =
                    journey.destinationStop {

                    Text(
                        destination
                            .displayNameEnglish
                    )
                    .font(.headline)

                } else {

                    Text(
                        "Destination unavailable"
                    )
                    .foregroundStyle(.secondary)
                }
            }

            Label(
                "\(orderedStops.count) stops",
                systemImage: "mappin.and.ellipse"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(
            .vertical,
            4
        )
    }
}
