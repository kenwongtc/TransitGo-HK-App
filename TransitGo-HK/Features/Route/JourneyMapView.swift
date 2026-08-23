//
//  JourneyMapView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import MapKit

struct JourneyMapView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    let journey: JourneyEntity

    @State
    private var shapeCoordinates:
        [CLLocationCoordinate2D] = []

    private var orderedStops: [JourneyStopEntity] {
        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    private var coordinates: [CLLocationCoordinate2D] {
        orderedStops.compactMap { journeyStop in
            guard let stop = journeyStop.stop else {
                return nil
            }

            return CLLocationCoordinate2D(
                latitude: stop.latitude,
                longitude: stop.longitude
            )
        }
    }

    private var pathCoordinates:
        [CLLocationCoordinate2D] {

        shapeCoordinates.isEmpty
            ? coordinates
            : shapeCoordinates
    }

    // MARK: - Circular Journey

    private var isCircularJourney: Bool {
        guard
            let firstStop = orderedStops.first?.stop,
            let lastStop = orderedStops.last?.stop
        else {
            return false
        }

        return firstStop.id == lastStop.id
    }

    // MARK: - Map Position

    private var mapPosition: MapCameraPosition {
        guard !coordinates.isEmpty else {
            return .automatic
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return .automatic
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let latitudeDelta = max(
            (maxLatitude - minLatitude) * 1.4,
            0.005
        )

        let longitudeDelta = max(
            (maxLongitude - minLongitude) * 1.4,
            0.005
        )

        return .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Map(
            initialPosition: mapPosition,
            interactionModes: [
                .pan,
                .zoom,
                .rotate
            ]
        ) {

            // MARK: Journey Path

            if pathCoordinates.count >= 2 {
                MapPolyline(
                    coordinates: pathCoordinates
                )
                .stroke(
                    .blue,
                    lineWidth: 4
                )
            }

            // MARK: Stop Markers

            ForEach(
                Array(orderedStops.enumerated()),
                id: \.element.id
            ) { index, journeyStop in

                if let stop = journeyStop.stop {

                    let coordinate = CLLocationCoordinate2D(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )

                    let isFirst =
                        index == 0

                    let isLast =
                        index == orderedStops.count - 1

                    // Circular journey:
                    //
                    // The first and last JourneyStopEntity
                    // represent the same physical stop.
                    //
                    // Draw the annotation only for the first
                    // occurrence so we don't get two markers
                    // on top of each other.

                    if isCircularJourney && isFirst {

                        Annotation(
                            "Start / End",
                            coordinate: coordinate
                        ) {
                            CircularEndpointAnnotation()
                        }

                    } else if isCircularJourney && isLast {

                        // Intentionally don't draw another
                        // annotation at the same physical stop.

                    } else if isFirst {

                        Annotation(
                            "Start",
                            coordinate: coordinate
                        ) {
                            EndpointAnnotation(
                                title: "Start",
                                sequence: journeyStop.sequence,
                                systemImage: "play.circle.fill"
                            )
                        }

                    } else if isLast {

                        Annotation(
                            "End",
                            coordinate: coordinate
                        ) {
                            EndpointAnnotation(
                                title: "End",
                                sequence: journeyStop.sequence,
                                systemImage: "flag.circle.fill"
                            )
                        }

                    } else {

                        Marker(
                            "\(journeyStop.sequence). \(stop.displayName(for: transitLanguage))",
                            coordinate: coordinate
                        )
                    }
                }
            }
        }
        .navigationTitle(
            journey.route?.number ?? "Journey Map"
        )
        .navigationBarTitleDisplayMode(.inline)
        .task(id: journey.id) {
            do {
                let shape = try await
                    JourneyShapeStore.shared.shape(
                        for: journey.id
                    )

                shapeCoordinates = shape?.coordinates
                    .map {
                        CLLocationCoordinate2D(
                            latitude: $0.latitude,
                            longitude: $0.longitude
                        )
                    } ?? []
            } catch {
                shapeCoordinates = []
            }
        }
    }
}


// MARK: - Endpoint Annotation

private struct EndpointAnnotation: View {

    let title: String
    let sequence: Int
    let systemImage: String

    var body: some View {
        VStack(spacing: 2) {

            Image(systemName: systemImage)
                .font(.title2)

            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)

            Text("\(sequence)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Circular Endpoint Annotation

private struct CircularEndpointAnnotation: View {

    var body: some View {
        VStack(spacing: 2) {

            Image(
                systemName: "arrow.trianglehead.2.clockwise.circle.fill"
            )
            .font(.title2)

            Text("Start / End")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }
}
