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

        let nearbyResolver =
            NearbyJourneyStopResolver()

        var bestJourney:
            JourneyEntity?

        var bestMatch:
            NearbyJourneyStopMatch?

        for journey in route.journeys {

            guard let match =
                nearbyResolver.nearestStop(
                    for: journey,
                    userLocation: userLocation
                )
            else {
                continue
            }

            if let currentBest = bestMatch {

                if match.distanceMeters <
                    currentBest.distanceMeters {

                    bestJourney = journey
                    bestMatch = match
                }

            } else {

                bestJourney = journey
                bestMatch = match
            }
        }

        guard
            let journey = bestJourney,
            let nearbyMatch = bestMatch,
            let stop = nearbyMatch.journeyStop.stop
        else {
            return nil
        }

        let match =
            NearbyRouteMatch(
                route: route,
                journey: journey,
                journeyStop:
                    nearbyMatch.journeyStop,
                stop: stop,
                distanceMeters:
                    nearbyMatch.distanceMeters
            )

        return try await resolve(
            match: match,
            modelContext: modelContext
        )
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

        guard let reference =
            try modelContext.fetch(
                descriptor
            ).first
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
