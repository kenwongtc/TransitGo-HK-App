//
//  RouteRowView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI
import CoreLocation

struct RouteRowView: View {

    @ScaledMetric(relativeTo: .title2)
    private var routeNumberWidth: CGFloat = 52

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Environment(\.locale)
    private var locale

    let route: RouteEntity
    let origin: String?
    let destination: String?
    let stopName: String?
    let stopCode: String?
    let etaResult: RouteETAResult?
    let isCompact: Bool
    let showsDistance: Bool
    let allowsTwoLineOrigin: Bool
    let allowsTwoLineDestination: Bool
    let showsDirectionIndicator: Bool
    let usesUniformNameStyle: Bool

    init(
        route: RouteEntity,
        origin: String? = nil,
        destination: String? = nil,
        stopName: String? = nil,
        stopCode: String? = nil,
        etaResult: RouteETAResult?,
        isCompact: Bool = false,
        showsDistance: Bool = true,
        allowsTwoLineOrigin: Bool = false,
        allowsTwoLineDestination: Bool = false,
        showsDirectionIndicator: Bool = true,
        usesUniformNameStyle: Bool = false
    ) {
        self.route = route
        self.origin = origin
        self.destination = destination
        self.stopName = stopName
        self.stopCode = stopCode
        self.etaResult = etaResult
        self.isCompact = isCompact
        self.showsDistance = showsDistance
        self.allowsTwoLineOrigin = allowsTwoLineOrigin
        self.allowsTwoLineDestination = allowsTwoLineDestination
        self.showsDirectionIndicator = showsDirectionIndicator
        self.usesUniformNameStyle = usesUniformNameStyle
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
                    width: routeNumberWidth,
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

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            origin
                            ?? route.displayOrigin(
                                for: transitLanguage
                            )
                        )
                        .font(
                            usesUniformNameStyle
                                ? .body
                                : .caption
                        )
                        .fontWeight(
                            usesUniformNameStyle
                                ? .medium
                                : .regular
                        )
                        .foregroundStyle(.primary)
                        .lineLimit(
                            allowsTwoLineOrigin ? 2 : 1
                        )

                        HStack(
                            alignment: .firstTextBaseline,
                            spacing: 4
                        ) {
                            if showsDirectionIndicator {
                                Text("to")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(
                                destination
                                ?? route.displayDestination(
                                    for: transitLanguage
                                )
                            )
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .fixedSize(
                                horizontal: false,
                                vertical:
                                    allowsTwoLineDestination
                            )
                            .lineLimit(
                                allowsTwoLineDestination
                                    ? 2
                                    : (isCompact ? 1 : 2)
                            )
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                    VStack(alignment: .trailing, spacing: 4) {
                        if showsDistance,
                            let etaResult
                        {

                            TimelineView(
                                .periodic(
                                    from: .now,
                                    by: 30
                                )
                            ) { context in

                                let arrivals =
                                    etaResult.etaRecords
                                        .compactMap {
                                            $0.estimatedArrival
                                        }

                                let nextArrival = arrivals
                                    .filter {
                                        $0 >= context.date
                                    }
                                    .sorted()
                                    .first

                                let hasDepartedArrival = arrivals
                                    .contains {
                                        $0 < context.date
                                    }

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

                                } else if hasDepartedArrival {

                                    Text("Last bus departed")
                                        .font(.caption)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                        .multilineTextAlignment(
                                            .trailing
                                        )

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

                        HStack(spacing: 4) {
                            if let adultFareText {
                                Text(verbatim: adultFareText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }

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
                }

                if stopName != nil
                    || (showsDistance && etaResult != nil)
                {
                    HStack(spacing: 8) {
                        if let stopName {
                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                Text(stopName)
                                    .font(.caption)
                                    .lineLimit(1)

                                if let stopCode {
                                    Text(verbatim: "(\(stopCode))")
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer(minLength: 8)

                        if showsDistance, let etaResult {
                            Text(
                                distanceText(
                                    etaResult.distanceMeters
                                )
                            )
                            .font(.caption2)
                            .lineLimit(1)
                        }
                    }
                    .foregroundStyle(.secondary)
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
            switch transitLanguage {
            case .english:
                return "Due"
            case .traditionalChinese:
                return "即將到站"
            case .simplifiedChinese:
                return "即将到站"
            }
        }

        switch transitLanguage {
        case .english:
            return "\(minutes) min"
        case .traditionalChinese:
            return "\(minutes) 分鐘"
        case .simplifiedChinese:
            return "\(minutes) 分钟"
        }
    }

    // MARK: - Operators

    private var adultFareText: String? {
        let fares = Array(
            Set(
                route.journeys.compactMap(
                    \.adultFullFareCents
                )
            )
        )
        .sorted()

        guard let minimumFare = fares.first else {
            return nil
        }

        if let maximumFare = fares.last,
           maximumFare != minimumFare {
            return "\(fareText(minimumFare))–\(fareText(maximumFare))"
        }

        return fareText(minimumFare)
    }

    private func fareText(_ cents: Int) -> String {
        let amount = String(
            format: "%.2f",
            Double(cents) / 100
        )

        return "$\(amount)"
    }

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
            let meters = Int(distance.rounded())

            switch transitLanguage {
            case .english:
                return "\(meters) m away"
            case .traditionalChinese:
                return "距離 \(meters) 米"
            case .simplifiedChinese:
                return "距离 \(meters) 米"
            }

        } else {
            let kilometers = String(
                format: "%.1f",
                locale: transitLanguage.locale,
                distance / 1000
            )

            switch transitLanguage {
            case .english:
                return "\(kilometers) km away"
            case .traditionalChinese:
                return "距離 \(kilometers) 公里"
            case .simplifiedChinese:
                return "距离 \(kilometers) 公里"
            }
        }
    }

}
