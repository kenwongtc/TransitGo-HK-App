//
//  JourneyStopListView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI

struct JourneyStopListView: View {

    let journey: JourneyEntity

    private var orderedStops: [JourneyStopEntity] {
        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    var body: some View {
        List {
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
            
            Section {
                ForEach(orderedStops) { journeyStop in

                    if let stop = journeyStop.stop {

                        NavigationLink {
                            StopDetailView(
                                stop: stop
                            )
                        } label: {
                            StopRowView(
                                journeyStop: journeyStop,
                                stop: stop
                            )
                        }

                    } else {

                        HStack(alignment: .top, spacing: 12) {

                            sequenceView(
                                journeyStop.sequence
                            )

                            Text("Stop unavailable")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

            } header: {
                Text("Stops: \(orderedStops.count)")
            }
        }
        .navigationTitle(
            journey.route?.number ?? "Journey"
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sequenceView(
        _ sequence: Int
    ) -> some View {

        Text("\(sequence)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(
                width: 28,
                alignment: .trailing
            )
    }
}


// MARK: - Stop Row

private struct StopRowView: View {

    let journeyStop: JourneyStopEntity
    let stop: StopEntity

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Text("\(journeyStop.sequence)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(
                    width: 28,
                    alignment: .trailing
                )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(stop.displayNameEnglish)
                    .font(.body)

                Text(stop.nameTraditional)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
