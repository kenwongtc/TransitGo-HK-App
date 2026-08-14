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

        matches.reserveCapacity(
            routes.count
        )

        for route in routes {

            var bestJourney:
                JourneyEntity?

            var bestJourneyStop:
                JourneyStopEntity?

            var bestStop:
                StopEntity?

            var bestDistance =
                CLLocationDistance.greatestFiniteMagnitude

            for journey in route.journeys {

                for journeyStop in journey.journeyStops {

                    guard
                        let stop =
                            journeyStop.stop,
                        let distance =
                            distanceByStopId[stop.id]
                    else {
                        continue
                    }

                    if distance < bestDistance {

                        bestDistance =
                            distance

                        bestJourney =
                            journey

                        bestJourneyStop =
                            journeyStop

                        bestStop =
                            stop
                    }
                }
            }

            guard
                bestDistance <= maximumDistanceMeters,
                let journey = bestJourney,
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
