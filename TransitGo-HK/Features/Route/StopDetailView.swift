//
//  StopDetailView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import MapKit

struct StopDetailView: View {

    let stop: StopEntity

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: stop.latitude,
            longitude: stop.longitude
        )
    }

    private var mapPosition: MapCameraPosition {
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
                        stop.nameEnglish,
                        coordinate: coordinate
                    )
                }
                .frame(height: 260)
                .listRowInsets(
                    EdgeInsets()
                )
            }

            // MARK: - Stop

            Section("Stop") {

                LabeledContent(
                    "ID",
                    value: stop.id
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("English")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(stop.nameEnglish)
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Traditional Chinese")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(stop.nameTraditional)
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Simplified Chinese")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(stop.nameSimplified)
                }
            }

            // MARK: - Location

            Section("Location") {

                LabeledContent(
                    "Latitude",
                    value: String(
                        format: "%.6f",
                        stop.latitude
                    )
                )

                LabeledContent(
                    "Longitude",
                    value: String(
                        format: "%.6f",
                        stop.longitude
                    )
                )
            }
        }
        .navigationTitle(stop.nameEnglish)
        .navigationBarTitleDisplayMode(.inline)
    }
}
