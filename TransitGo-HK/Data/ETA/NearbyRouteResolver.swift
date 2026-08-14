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
        limit: Int = 20
    ) -> [NearbyRouteMatch] {

        // -----------------------------------
        // 1. Collect unique physical stops.
        //
        // A physical stop can appear in many
        // routes/journeys. We only want to
        // calculate its geographic distance once.
        // -----------------------------------

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

        // -----------------------------------
        // 2. Calculate distance once per stop.
        // -----------------------------------

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

        // -----------------------------------
        // 3. Find the closest stop/journey
        //    for each route.
        // -----------------------------------

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

        // -----------------------------------
        // 4. Sort geographically and keep
        //    only the nearest route candidates.
        // -----------------------------------

        matches.sort {
            $0.distanceMeters <
                $1.distanceMeters
        }

        return Array(
            matches.prefix(limit)
        )
    }
}
