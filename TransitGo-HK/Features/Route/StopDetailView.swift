//
//  StopDetailView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData
import MapKit

struct StopDetailView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.transitLanguage)
    private var transitLanguage

    let stop: StopEntity

    let journey: JourneyEntity?
    let journeyStop: JourneyStopEntity?

    @State
    private var etaResult:
        RouteETAResult?

    @State
    private var isLoadingETA =
        false

    init(
        stop: StopEntity,
        journey: JourneyEntity? = nil,
        journeyStop: JourneyStopEntity? = nil
    ) {
        self.stop = stop
        self.journey = journey
        self.journeyStop = journeyStop
    }

    private var coordinate:
        CLLocationCoordinate2D {

        CLLocationCoordinate2D(
            latitude: stop.latitude,
            longitude: stop.longitude
        )
    }

    private var mapPosition:
        MapCameraPosition {

        .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.005,
                    longitudeDelta: 0.005
                )
            )
        )
    }

    private var operatorIds: [String] {
        Array(
            Set(
                journey?.route?.operators.flatMap {
                    $0.id.split(separator: "+")
                        .map(String.init)
                } ?? []
            )
        )
        .sorted()
    }

    var body: some View {

        List {

            // MARK: - Map

            Section {

                Map(
                    initialPosition: mapPosition,
                    interactionModes: [
                        .pan,
                        .zoom
                    ]
                ) {

                    Marker(
                        stop.displayName(for: transitLanguage),
                        coordinate: coordinate
                    )
                }
                .frame(height: 260)
                .listRowInsets(
                    EdgeInsets()
                )
            }

            // MARK: - ETA

            if journey != nil &&
                journeyStop != nil {

                Section("ETA") {

                    if isLoadingETA {

                        ProgressView(
                            "Loading arrivals..."
                        )

                    } else if let etaResult {

                        TimelineView(
                            .periodic(
                                from: .now,
                                by: 1
                            )
                        ) { context in

                            let upcoming =
                                etaResult
                                    .etaRecords
                                    .filter {
                                        guard let date =
                                            $0.estimatedArrival
                                        else {
                                            return false
                                        }

                                        return date >=
                                            context.date
                                    }
                                    .sorted {
                                        guard
                                            let lhs =
                                                $0.estimatedArrival,
                                            let rhs =
                                                $1.estimatedArrival
                                        else {
                                            return false
                                        }

                                        return lhs < rhs
                                    }
                                    .prefix(6)

                            if upcoming.isEmpty {

                                Text(
                                    "No upcoming arrivals"
                                )
                                .foregroundStyle(
                                    .secondary
                                )

                            } else {

                                ForEach(
                                    Array(
                                        upcoming.enumerated()
                                    ),
                                    id: \.offset
                                ) { _, eta in

                                    HStack {

                                        VStack(
                                            alignment: .leading,
                                            spacing: 2
                                        ) {

                                            CustomBadgeView(
                                                operatorId:
                                                    eta.operatorId
                                            )

                                            if !eta
                                                .destinationEnglish
                                                .isEmpty {

                                                Text(
                                                    eta.destinationEnglish
                                                )
                                                .font(.caption2)
                                                .foregroundStyle(
                                                    .secondary
                                                )
                                            }
                                        }

                                        Spacer()

                                        if let date =
                                            eta.estimatedArrival {

                                            Text(
                                                date,
                                                style: .relative
                                            )
                                            .font(.headline)
                                        }
                                    }
                                    .padding(
                                        .vertical,
                                        2
                                    )
                                }
                            }
                        }

                    } else {

                        Text(
                            "ETA unavailable"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
                .listRowBackground(
                    Color(uiColor: .systemBackground)
                        .opacity(0.92)
                )
            }

        }
        .scrollContentBackground(.hidden)
        .background {
            CustomOperatorBackgroundView(
                operatorIds: operatorIds
            )
        }
        .navigationTitle(
            stop.displayName(for: transitLanguage)
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {
            await loadETA()
        }
    }

    // MARK: - ETA Loading

    @MainActor
    private func loadETA() async {

        guard
            let journey,
            let journeyStop
        else {
            return
        }

        isLoadingETA = true

        defer {
            isLoadingETA = false
        }

        do {

            etaResult =
                try await RouteETAResolver()
                    .resolve(
                        journey: journey,
                        journeyStop: journeyStop,
                        modelContext: modelContext
                    )

        } catch {

            print(
                "Stop ETA load failed:",
                error
            )
        }
    }

}
