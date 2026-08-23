//
//  NearbyRouteResolver.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import Foundation
import CoreLocation

struct NearbyRouteMatch {

    let route: RouteEntity
    let journey: JourneyEntity
    let journeyStop: JourneyStopEntity
    let stop: StopEntity
    let distanceMeters: CLLocationDistance
}

struct NearbyRouteResolver {

    func nearbyRoutes(
        from routes: [RouteEntity],
        operatorStopReferences:
            [OperatorStopReferenceEntity] = [],
        userLocation: CLLocation,
        maximumDistanceMeters: CLLocationDistance = 500,
        maximumRoutes: Int = 100
    ) -> [NearbyRouteMatch] {

        var uniqueStops:
            [String: StopEntity] = [:]

        for route in routes {

            for journey in route.journeys {

                for journeyStop in journey.journeyStops {

                    guard let stop =
                        journeyStop.stop
                    else {
                        continue
                    }

                    uniqueStops[stop.id] =
                        stop
                }
            }
        }

        var distanceByStopId:
            [String: CLLocationDistance] = [:]

        distanceByStopId.reserveCapacity(
            uniqueStops.count
        )

        for (stopId, stop) in uniqueStops {

            let stopLocation =
                CLLocation(
                    latitude: stop.latitude,
                    longitude: stop.longitude
                )

            let distance =
                userLocation.distance(
                    from: stopLocation
                )

            distanceByStopId[stopId] =
                distance
        }

        var matches:
            [NearbyRouteMatch] = []

        let operatorCoordinateByJourneyStop =
            Dictionary(
                operatorStopReferences.compactMap {
                    reference ->
                        (String, CLLocation)? in

                    guard
                        let latitude =
                            reference.operatorLatitude,
                        let longitude =
                            reference.operatorLongitude
                    else {
                        return nil
                    }

                    let key =
                        "\(reference.journeyId)|\(reference.sequence)"

                    return (
                        key,
                        CLLocation(
                            latitude: latitude,
                            longitude: longitude
                        )
                    )
                },
                uniquingKeysWith: { first, _ in first }
            )

        matches.reserveCapacity(
            routes.reduce(0) {
                $0 + $1.journeys.count
            }
        )

        for route in routes {

            for journey in route.journeys {

                var bestJourneyStop:
                    JourneyStopEntity?

                var bestStop:
                    StopEntity?

                var bestDistance =
                    CLLocationDistance.greatestFiniteMagnitude

                for journeyStop in journey.journeyStops {

                    guard let stop =
                        journeyStop.stop
                    else {
                        continue
                    }

                    let referenceKey =
                        "\(journey.id)|\(journeyStop.sequence)"

                    let distance =
                        operatorCoordinateByJourneyStop[
                            referenceKey
                        ]
                        .map {
                            userLocation.distance(from: $0)
                        }
                        ?? distanceByStopId[stop.id]
                        ?? CLLocationDistance
                            .greatestFiniteMagnitude

                    if distance < bestDistance {

                        bestDistance =
                            distance

                        bestJourneyStop =
                            journeyStop

                        bestStop =
                            stop
                    }
                }

                guard
                    bestDistance <= maximumDistanceMeters,
                    let journeyStop = bestJourneyStop,
                    let stop = bestStop
                else {
                    continue
                }

                matches.append(
                    NearbyRouteMatch(
                        route: route,
                        journey: journey,
                        journeyStop: journeyStop,
                        stop: stop,
                        distanceMeters: bestDistance
                    )
                )
            }
        }

        var deduplicated:
            [String: NearbyRouteMatch] = [:]

        for match in matches {

            let operatorKey =
                match.route.operators
                    .map {
                        $0.id
                    }
                    .sorted()
                    .joined(
                        separator: "+"
                    )

            let destinationKey =
                match.journey
                    .destinationStop?
                    .id
                ??
                match.route
                    .destinationEnglish

            let key =
                [
                    operatorKey,
                    match.route.number,
                    destinationKey
                ]
                .joined(
                    separator: "|"
                )

            if let existing =
                deduplicated[key] {

                if match.distanceMeters <
                    existing.distanceMeters {

                    deduplicated[key] =
                        match
                }

            } else {

                deduplicated[key] =
                    match
            }
        }

        matches =
            Array(
                deduplicated.values
            )
        
        matches.sort {
            $0.distanceMeters <
                $1.distanceMeters
        }

        return Array(
            matches.prefix(
                maximumRoutes
            )
        )
    }
}
