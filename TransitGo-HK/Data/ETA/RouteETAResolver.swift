//
//  RouteETAResolver.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import Foundation
import CoreLocation
import SwiftData

struct RouteETAResult {

    let journey: JourneyEntity
    let journeyStop: JourneyStopEntity
    let stop: StopEntity

    let distanceMeters: CLLocationDistance

    let reference: OperatorStopReferenceEntity

    let etaRecords: [TransitETA]
}

@MainActor
struct RouteETAResolver {

    private let etaProvider =
        ETAProvider()

    // MARK: - Route + Location

    func resolve(
        route: RouteEntity,
        userLocation: CLLocation,
        modelContext: ModelContext
    ) async throws -> RouteETAResult? {

        var candidates:
            [NearbyRouteMatch] = []

        for journey in route.journeys {

            for journeyStop in journey.journeyStops {

                guard let stop =
                    journeyStop.stop
                else {
                    continue
                }

                let stopLocation =
                    CLLocation(
                        latitude:
                            stop.latitude,
                        longitude:
                            stop.longitude
                    )

                let distance =
                    userLocation.distance(
                        from: stopLocation
                    )

                candidates.append(
                    NearbyRouteMatch(
                        route:
                            route,
                        journey:
                            journey,
                        journeyStop:
                            journeyStop,
                        stop:
                            stop,
                        distanceMeters:
                            distance
                    )
                )
            }
        }

        candidates.sort {
            $0.distanceMeters <
                $1.distanceMeters
        }

        for candidate in candidates {

            let journeyId =
                candidate.journey.id

            let sequence =
                candidate.journeyStop.sequence

            let stopId =
                candidate.stop.id

            let descriptor =
                FetchDescriptor<
                    OperatorStopReferenceEntity
                >(
                    predicate: #Predicate {
                        $0.journeyId == journeyId &&
                        $0.sequence == sequence &&
                        $0.stopId == stopId
                    }
                )

            let references =
                try modelContext.fetch(
                    descriptor
                )

            guard
                !references.isEmpty
            else {
                continue
            }

            return try await resolve(
                match:
                    candidate,
                modelContext:
                    modelContext
            )
        }

        return nil
    }

    // MARK: - Existing Nearby Match

    func resolve(
        match: NearbyRouteMatch,
        modelContext: ModelContext
    ) async throws -> RouteETAResult? {

        let route =
            match.route

        let journey =
            match.journey

        let journeyStop =
            match.journeyStop

        let stop =
            match.stop

        let journeyId =
            journey.id

        let sequence =
            journeyStop.sequence

        let stopId =
            stop.id

        let descriptor =
            FetchDescriptor<
                OperatorStopReferenceEntity
            >(
                predicate: #Predicate {
                    $0.journeyId == journeyId &&
                    $0.sequence == sequence &&
                    $0.stopId == stopId
                }
            )

        let references =
            try modelContext.fetch(
                descriptor
            )

        guard let reference =
            references.first
        else {

            return nil
        }

        let bound: String?

        switch journey.direction {

        case "1":
            bound = "O"

        case "2":
            bound = "I"

        default:
            bound = nil
        }

        let etaRecords =
            try await etaProvider.fetchETA(
                reference: reference,
                routeNumber: route.number,
                bound: bound
            )

        return RouteETAResult(
            journey: journey,
            journeyStop: journeyStop,
            stop: stop,
            distanceMeters:
                match.distanceMeters,
            reference: reference,
            etaRecords: etaRecords
        )
    }
}
