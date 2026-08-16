//
//  RouteRowView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI
import CoreLocation

struct RouteRowView: View {

    let route: RouteEntity
    let etaResult: RouteETAResult?

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(route.number)
                    .font(.headline)

                if let operatorEntity =
                    route.operators.first {

                    Text(operatorEntity.nameEnglish)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let etaResult {

                    Text(
                        destinationText(
                            for: etaResult
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text(etaResult.stop.displayNameEnglish)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        distanceText(
                            etaResult.distanceMeters
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let etaResult {

                let upcoming =
                    etaResult.etaRecords
                        .compactMap {
                            $0.estimatedArrival
                        }
                        .sorted()
                        .prefix(3)

                VStack(
                    alignment: .trailing,
                    spacing: 4
                ) {

                    if upcoming.isEmpty {

                        Text("No ETA")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                    } else {

                        ForEach(
                            Array(upcoming),
                            id: \.self
                        ) { arrival in

                            Text(
                                etaText(
                                    for: arrival
                                )
                            )
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - ETA Text

    private func etaText(
        for arrival: Date
    ) -> String {

        let seconds =
            arrival.timeIntervalSinceNow

        let minutes =
            Int(seconds / 60)

        if minutes <= 0 {
            return "Due"
        }

        return "\(minutes) min"
    }

    // MARK: - Distance Text

    private func distanceText(
        _ distance: CLLocationDistance
    ) -> String {

        if distance < 1000 {

            return String(
                format: "%.0f m away",
                distance
            )

        } else {

            return String(
                format: "%.1f km away",
                distance / 1000
            )
        }
    }
    
    // MARK: - Destination Text

    private func destinationText(
        for etaResult: RouteETAResult
    ) -> String {

        if let firstETA =
            etaResult.etaRecords.first,
           !firstETA.destinationEnglish.isEmpty {

            return "→ \(firstETA.destinationEnglish)"
        }

        if !route.destinationEnglish.isEmpty {
            return "→ \(route.destinationEnglish)"
        }

        return ""
    }

}
