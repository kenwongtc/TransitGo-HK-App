//
//  NearbyJourneyStopResolver.swift
//  TransitGo-HK
//
//  Created by Ken on 13/8/2026.
//

import Foundation
import CoreLocation

struct NearbyJourneyStopMatch {

    let journeyStop: JourneyStopEntity
    let distanceMeters: CLLocationDistance
}

struct NearbyJourneyStopResolver {

    func nearestStop(
        for journey: JourneyEntity,
        userLocation: CLLocation
    ) -> NearbyJourneyStopMatch? {

        var bestMatch: NearbyJourneyStopMatch?

        for journeyStop in journey.journeyStops {

            guard let stop = journeyStop.stop else {
                continue
            }

            let stopLocation = CLLocation(
                latitude: stop.latitude,
                longitude: stop.longitude
            )

            let distance =
                userLocation.distance(
                    from: stopLocation
                )

            if let currentBest = bestMatch {

                if distance <
                    currentBest.distanceMeters {

                    bestMatch =
                        NearbyJourneyStopMatch(
                            journeyStop: journeyStop,
                            distanceMeters: distance
                        )
                }

            } else {

                bestMatch =
                    NearbyJourneyStopMatch(
                        journeyStop: journeyStop,
                        distanceMeters: distance
                    )
            }
        }

        return bestMatch
    }
}
