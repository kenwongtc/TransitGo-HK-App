//
//  RouteRowView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI
import CoreLocation

struct RouteRowView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    let route: RouteEntity
    let destination: String?
    let etaResult: RouteETAResult?
    let isCompact: Bool

    init(
        route: RouteEntity,
        destination: String? = nil,
        etaResult: RouteETAResult?,
        isCompact: Bool = false
    ) {
        self.route = route
        self.destination = destination
        self.etaResult = etaResult
        self.isCompact = isCompact
    }

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 10
        ) {

            // MARK: Route Number

            Text(route.number)
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(
                    width: 52,
                    alignment: .leading
                )

            // MARK: Route Information

            VStack(
                alignment: .trailing,
                spacing: isCompact ? 2 : 6
            ) {

                HStack(
                    alignment: .bottom,
                    spacing: 10
                ) {

                    Text(
                        destination
                        ?? route.displayDestination(for: transitLanguage)
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(isCompact ? 1 : 2)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                    if let etaResult {

                        TimelineView(
                            .periodic(
                                from: .now,
                                by: 30
                            )
                        ) { context in

                            let nextArrival =
                                etaResult.etaRecords
                                    .compactMap {
                                        $0.estimatedArrival
                                    }
                                    .filter {
                                        $0 >= context.date
                                    }
                                    .sorted()
                                    .first

                            if let nextArrival {

                                Text(
                                    etaText(
                                        for: nextArrival,
                                        relativeTo:
                                            context.date
                                    )
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .monospacedDigit()

                            } else {

                                Text("No ETA")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }
                        }
                        .frame(
                            minWidth: 58,
                            alignment: .trailing
                        )
                    }
                }

                HStack(spacing: 8) {

                    if let etaResult {

                        Text(
                            distanceText(
                                etaResult
                                    .distanceMeters
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer(minLength: 8)

                    ForEach(
                        operatorIds,
                        id: \.self
                    ) { operatorId in

                        CustomBadgeView(
                            operatorId: operatorId,
                            isCompact: true
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, isCompact ? 0 : 2)
    }

    // MARK: - ETA Text

    private func etaText(
        for arrival: Date,
        relativeTo date: Date
    ) -> String {

        let seconds =
            arrival.timeIntervalSince(
                date
            )

        let minutes =
            Int(seconds / 60)

        if minutes <= 0 {
            return "Due"
        }

        return "\(minutes) min"
    }

    // MARK: - Operators

    private var operatorIds: [String] {

        Array(
            Set(
                route.operators.flatMap {
                    $0.id.split(separator: "+")
                        .map(String.init)
                }
            )
        )
        .sorted()
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
    
}
