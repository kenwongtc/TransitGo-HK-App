//
//  RouteDetailView.swift
//  TransitGo-HK
//
//  Created by Ken on 17/8/2026.
//

import SwiftUI

struct RouteDetailView: View {

    let route: RouteEntity

    private var journeys: [JourneyEntity] {
        route.journeys.sorted {
            $0.direction < $1.direction
        }
    }

    private var isCircular: Bool {
        route.destinationEnglish
            .localizedCaseInsensitiveContains(
                "(CIRCULAR)"
            )
    }

    private var circularDestination: String {
        route.destinationEnglish
            .replacingOccurrences(
                of: "(CIRCULAR)",
                with: "",
                options:
                    .caseInsensitive
            )
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }

    private var operatorNames: String {
        route.operators
            .map {
                $0.nameEnglish
            }
            .sorted()
            .joined(
                separator: " • "
            )
    }

    var body: some View {

        List {

            // MARK: - Route Summary

            Section {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    HStack(
                        alignment: .firstTextBaseline
                    ) {

                        Text(route.number)
                            .font(
                                .largeTitle
                                    .bold()
                            )

                        Spacer()

                        if !operatorNames.isEmpty {

                            Text(
                                operatorNames
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }

                    Divider()

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(
                            route.originEnglish
                        )
                        .font(.headline)

                        HStack(spacing: 8) {

                            Image(
                                systemName:
                                    isCircular
                                    ? "arrow.trianglehead.2.clockwise"
                                    : "arrow.down"
                            )
                            .foregroundStyle(
                                .secondary
                            )

                            Text(
                                isCircular
                                ? "Circular"
                                : "to"
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Text(
                            isCircular
                            ? circularDestination
                            : route.destinationEnglish
                        )
                        .font(.headline)
                    }
                }
                .padding(
                    .vertical,
                    6
                )
            }

            // MARK: - Journeys

            Section {

                if journeys.isEmpty {

                    Text("No journeys")
                        .foregroundStyle(
                            .secondary
                        )

                } else {

                    ForEach(
                        journeys
                    ) { journey in

                        NavigationLink {

                            JourneyStopListView(
                                journey:
                                    journey
                            )

                        } label: {

                            JourneySummaryView(
                                journey:
                                    journey,
                                isCircular:
                                    isCircular,
                                circularDestination:
                                    circularDestination
                            )
                        }
                    }
                }

            } header: {

                Text("Journeys")
            }
        }
        .navigationTitle(
            "Route \(route.number)"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
