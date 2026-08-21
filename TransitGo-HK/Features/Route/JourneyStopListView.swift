//
//  JourneyStopListView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData

struct JourneyStopListView: View {

    let journey: JourneyEntity

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var etaResults:
        [String: RouteETAResult] = [:]

    @State
    private var loadingStopIds:
        Set<String> = []

    @State
    private var unavailableStopIds:
        Set<String> = []

    @State
    private var failedStopIds:
        Set<String> = []

    private var orderedStops:
        [JourneyStopEntity] {

        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    var body: some View {

        List {

            // MARK: - Journey Summary

            Section {

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
                    }

                    HStack(spacing: 8) {

                        Image(
                            systemName: "arrow.down"
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        Text("to")
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    if let destination =
                        journey.destinationStop {

                        Text(
                            destination
                                .displayNameEnglish
                        )
                        .font(.headline)
                    }

                    Label(
                        "\(orderedStops.count) stops",
                        systemImage:
                            "mappin.and.ellipse"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
                .padding(
                    .vertical,
                    4
                )
            }

            // MARK: - Map

            Section {

                NavigationLink {

                    JourneyMapView(
                        journey: journey
                    )

                } label: {

                    Label(
                        "View Journey Map",
                        systemImage: "map"
                    )
                }
            }

            // MARK: - Stops

            Section {

                ForEach(
                    orderedStops
                ) { journeyStop in

                    if let stop =
                        journeyStop.stop {

                        NavigationLink {

                            StopDetailView(
                                stop: stop,
                                journey: journey,
                                journeyStop:
                                    journeyStop
                            )

                        } label: {

                            StopRowView(
                                journeyStop:
                                    journeyStop,
                                stop:
                                    stop,
                                etaResult:
                                    etaResults[
                                        journeyStop.id
                                    ],
                                isLoadingETA:
                                    loadingStopIds
                                        .contains(
                                            journeyStop.id
                                        ),
                                isETAUnavailable:
                                    unavailableStopIds
                                        .contains(
                                            journeyStop.id
                                        ),
                                didETAFail:
                                    failedStopIds
                                        .contains(
                                            journeyStop.id
                                        )
                            )
                            .task {

                                await loadETA(
                                    for:
                                        journeyStop
                                )
                            }
                        }

                    } else {

                        HStack(
                            alignment: .top,
                            spacing: 12
                        ) {

                            sequenceView(
                                journeyStop.sequence
                            )

                            Text(
                                "Stop unavailable"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }
                        .padding(
                            .vertical,
                            4
                        )
                    }
                }

            } header: {

                Text(
                    "Stops: \(orderedStops.count)"
                )
            }
        }
        .navigationTitle(
            journey.route?.number
            ?? "Journey"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }

    // MARK: - Stop ETA

    @MainActor
    private func loadETA(
        for journeyStop:
            JourneyStopEntity
    ) async {

        let stopId =
            journeyStop.id

        guard
            etaResults[stopId] == nil,
            !unavailableStopIds
                .contains(stopId),
            !failedStopIds
                .contains(stopId),
            !loadingStopIds
                .contains(stopId)
        else {
            return
        }

        loadingStopIds.insert(
            stopId
        )

        defer {

            loadingStopIds.remove(
                stopId
            )
        }

        do {

            let result =
                try await RouteETAResolver()
                    .resolve(
                        journey: journey,
                        journeyStop:
                            journeyStop,
                        modelContext:
                            modelContext
                    )

            if let result {

                etaResults[stopId] =
                    result

            } else {

                unavailableStopIds
                    .insert(stopId)
            }

        } catch {

            failedStopIds.insert(
                stopId
            )

            print(
                "Stop ETA load failed",
                journeyStop.sequence,
                ":",
                error
            )
        }
    }

    // MARK: - Sequence

    private func sequenceView(
        _ sequence: Int
    ) -> some View {

        Text("\(sequence)")
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            .frame(
                width: 28,
                alignment: .trailing
            )
    }
}


// MARK: - Stop Row

private struct StopRowView: View {

    let journeyStop:
        JourneyStopEntity

    let stop:
        StopEntity

    let etaResult:
        RouteETAResult?

    let isLoadingETA: Bool

    let isETAUnavailable: Bool

    let didETAFail: Bool

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Text(
                "\(journeyStop.sequence)"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            .frame(
                width: 28,
                alignment: .trailing
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    stop.displayNameEnglish
                )
                .font(.body)

                Text(
                    stop.displayNameTraditional
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            // MARK: ETA

            if isLoadingETA {

                ProgressView()
                    .controlSize(.small)

            } else if isETAUnavailable {

                Text("Unavailable")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

            } else if didETAFail {

                Text("Error")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

            } else {

                TimelineView(
                    .periodic(
                        from: .now,
                        by: 1
                    )
                ) { context in

                    if let nextArrival =
                        nextArrival(
                            at: context.date
                        ) {

                        Text(
                            etaText(
                                for: nextArrival,
                                relativeTo:
                                    context.date
                            )
                        )
                        .font(.subheadline)
                        .monospacedDigit()

                    } else if etaResult != nil {

                        Text("No ETA")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
            }
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Next Arrival

    private func nextArrival(
        at date: Date
    ) -> Date? {

        etaResult?
            .etaRecords
            .compactMap {
                $0.estimatedArrival
            }
            .filter {
                $0 >= date
            }
            .min()
    }

    // MARK: - ETA Text

    private func etaText(
        for arrival: Date,
        relativeTo date: Date
    ) -> String {

        let seconds =
            max(
                0,
                Int(
                    arrival
                        .timeIntervalSince(
                            date
                        )
                )
            )

        let minutes =
            seconds / 60

        let remainingSeconds =
            seconds % 60

        if minutes == 0 {

            return "\(remainingSeconds)s"
        }

        return
            "\(minutes)m \(remainingSeconds)s"
    }
}
