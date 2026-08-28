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

struct NearbyRouteIndex: Sendable {

    private let candidates: [NearbyRouteCandidate]

    private init(candidates: [NearbyRouteCandidate]) {
        self.candidates = candidates
    }

    @MainActor
    static func prepare(
        routes: [RouteEntity],
        operatorStopReferences: [OperatorStopReferenceEntity]
    ) async -> NearbyRoutePreparation {
        var operatorCoordinates:
            [String: NearbyRouteCoordinate] = [:]

        for (index, reference) in
            operatorStopReferences.enumerated() {

            if let latitude = reference.operatorLatitude,
               let longitude = reference.operatorLongitude {
                let key =
                    "\(reference.journeyId)|\(reference.sequence)"

                if operatorCoordinates[key] == nil {
                    operatorCoordinates[key] =
                        NearbyRouteCoordinate(
                            latitude: latitude,
                            longitude: longitude
                        )
                }
            }

            if index.isMultiple(of: 1_000) {
                await Task.yield()

                if Task.isCancelled {
                    return NearbyRoutePreparation(
                        index: NearbyRouteIndex(
                            candidates: []
                        ),
                        matchesByJourneyStopId: [:]
                    )
                }
            }
        }

        var builtCandidates: [NearbyRouteCandidate] = []
        var matchesByJourneyStopId:
            [String: NearbyRouteMatch] = [:]

        for (routeIndex, route) in routes.enumerated() {
            let operatorKey = route.operators
                .map(\.id)
                .sorted()
                .joined(separator: "+")

            for journey in route.journeys {
                let destinationKey =
                    journey.destinationStop?.id
                    ?? route.destinationEnglish

                for journeyStop in journey.journeyStops {
                    guard let stop = journeyStop.stop else {
                        continue
                    }

                    let coordinate = operatorCoordinates[
                        "\(journey.id)|\(journeyStop.sequence)"
                    ] ?? NearbyRouteCoordinate(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )

                    builtCandidates.append(
                        NearbyRouteCandidate(
                            journeyStopId: journeyStop.id,
                            stopId: stop.id,
                            stopName: stop.nameEnglish,
                            routeNumber: route.number,
                            operatorKey: operatorKey,
                            destinationKey: destinationKey,
                            coordinate: coordinate
                        )
                    )

                    matchesByJourneyStopId[journeyStop.id] =
                        NearbyRouteMatch(
                            route: route,
                            journey: journey,
                            journeyStop: journeyStop,
                            stop: stop,
                            distanceMeters: 0
                        )
                }
            }

            if routeIndex.isMultiple(of: 10) {
                await Task.yield()

                if Task.isCancelled {
                    return NearbyRoutePreparation(
                        index: NearbyRouteIndex(
                            candidates: []
                        ),
                        matchesByJourneyStopId: [:]
                    )
                }
            }
        }

        return NearbyRoutePreparation(
            index: NearbyRouteIndex(
                candidates: builtCandidates
            ),
            matchesByJourneyStopId:
                matchesByJourneyStopId
        )
    }

    nonisolated func nearbyJourneyStops(
        latitude: Double,
        longitude: Double,
        maximumDistanceMeters: CLLocationDistance,
        maximumRoutes: Int
    ) -> [NearbyRouteCandidateResult] {
        var nearbyResults: [NearbyRouteCandidateResult] = []

        for candidate in candidates {
            let distance = candidate.coordinate.distance(
                toLatitude: latitude,
                longitude: longitude
            )

            guard distance <= maximumDistanceMeters else {
                continue
            }

            let result = NearbyRouteCandidateResult(
                journeyStopId: candidate.journeyStopId,
                stopId: candidate.stopId,
                stopName: candidate.stopName,
                routeNumber: candidate.routeNumber,
                operatorKey: candidate.operatorKey,
                destinationKey: candidate.destinationKey,
                coordinate: candidate.coordinate,
                distanceMeters: distance
            )

            nearbyResults.append(result)
        }

        guard let anchor = nearbyResults.min(
            by: { $0.distanceMeters < $1.distanceMeters }
        ) else {
            return []
        }

        let stopAreaResults = nearbyResults.filter {
            NearbyStopAreaMatcher.belongsToArea(
                candidate: $0,
                anchoredAt: anchor
            )
        }

        var deduplicated:
            [String: NearbyRouteCandidateResult] = [:]

        for result in stopAreaResults {
            let key = [
                result.operatorKey,
                result.routeNumber,
                result.destinationKey,
                result.stopId
            ].joined(separator: "|")

            if let existing = deduplicated[key],
               existing.distanceMeters <= result.distanceMeters {
                continue
            }

            deduplicated[key] = result
        }

        let routeGroups:
            [String: [NearbyRouteCandidateResult]] = Dictionary(
            grouping: deduplicated.values
        ) { result in
            "\(result.operatorKey)|\(result.routeNumber)"
        }

        let orderedResults:
            [NearbyRouteCandidateResult] = routeGroups.values
            .map { group in
                group.sorted {
                    $0.distanceMeters < $1.distanceMeters
                }
            }
            .sorted { lhs, rhs in
                guard
                    let lhsDistance = lhs.first?.distanceMeters,
                    let rhsDistance = rhs.first?.distanceMeters
                else {
                    return !lhs.isEmpty
                }

                return lhsDistance < rhsDistance
            }
            .flatMap { $0 }

        return orderedResults
            .prefix(maximumRoutes)
            .map { $0 }
    }
}

struct NearbyRoutePreparation {
    let index: NearbyRouteIndex
    let matchesByJourneyStopId: [String: NearbyRouteMatch]
}

private struct NearbyRouteCandidate: Sendable {
    let journeyStopId: String
    let stopId: String
    let stopName: String
    let routeNumber: String
    let operatorKey: String
    let destinationKey: String
    let coordinate: NearbyRouteCoordinate
}

struct NearbyRouteCandidateResult: Sendable {
    let journeyStopId: String
    let stopId: String
    let stopName: String
    let routeNumber: String
    let operatorKey: String
    let destinationKey: String
    fileprivate let coordinate: NearbyRouteCoordinate
    let distanceMeters: CLLocationDistance
}

private enum NearbyStopAreaMatcher {
    nonisolated static let maximumAreaRadiusMeters = 100.0

    // Add known physical-stop IDs here when an interchange's
    // published names do not identify the same place reliably.
    nonisolated static let manualGroupByStopId: [String: String] = [:]

    nonisolated static func belongsToArea(
        candidate: NearbyRouteCandidateResult,
        anchoredAt anchor: NearbyRouteCandidateResult
    ) -> Bool {
        guard candidate.coordinate.distance(
            to: anchor.coordinate
        ) <= maximumAreaRadiusMeters else {
            return false
        }

        if candidate.stopId == anchor.stopId {
            return true
        }

        if let candidateGroup = manualGroupByStopId[candidate.stopId],
           candidateGroup == manualGroupByStopId[anchor.stopId] {
            return true
        }

        let candidateTokens = significantTokens(candidate.stopName)
        let anchorTokens = significantTokens(anchor.stopName)
        let sharedTokens = candidateTokens.intersection(anchorTokens)

        guard !sharedTokens.isEmpty else {
            return false
        }

        let smallerTokenCount = min(
            candidateTokens.count,
            anchorTokens.count
        )

        return smallerTokenCount > 0 &&
            Double(sharedTokens.count) /
                Double(smallerTokenCount) >= 0.6
    }

    nonisolated private static func significantTokens(
        _ name: String
    ) -> Set<String> {
        let ignored: Set<String> = [
            "bus", "stop", "station", "terminus",
            "interchange", "road", "street", "outside",
            "opposite", "near"
        ]

        return Set(
            name.lowercased()
                .components(
                    separatedBy: CharacterSet
                        .alphanumerics
                        .inverted
                )
                .filter {
                    $0.count > 1 && !ignored.contains($0)
                }
        )
    }
}

fileprivate struct NearbyRouteCoordinate: Sendable {
    let latitude: Double
    let longitude: Double

    nonisolated func distance(
        toLatitude targetLatitude: Double,
        longitude targetLongitude: Double
    ) -> CLLocationDistance {
        let earthRadius = 6_371_000.0
        let latitudeDelta = (targetLatitude - latitude) * .pi / 180
        let longitudeDelta = (targetLongitude - longitude) * .pi / 180
        let startLatitude = latitude * .pi / 180
        let targetLatitude = targetLatitude * .pi / 180

        let a = pow(sin(latitudeDelta / 2), 2) +
            cos(startLatitude) * cos(targetLatitude) *
            pow(sin(longitudeDelta / 2), 2)

        return earthRadius * 2 * atan2(
            sqrt(a),
            sqrt(1 - a)
        )
    }

    nonisolated func distance(
        to other: NearbyRouteCoordinate
    ) -> CLLocationDistance {
        distance(
            toLatitude: other.latitude,
            longitude: other.longitude
        )
    }
}

struct NearbyRouteResolver {

    func nearbyRoutes(
        from routes: [RouteEntity],
        stops: [StopEntity],
        operatorStopReferences:
            [OperatorStopReferenceEntity] = [],
        userLocation: CLLocation,
        maximumDistanceMeters: CLLocationDistance = 500,
        maximumRoutes: Int = 100
    ) -> [NearbyRouteMatch] {

        var distanceByStopId:
            [String: CLLocationDistance] = [:]

        distanceByStopId.reserveCapacity(
            stops.count
        )

        for stop in stops {

            let stopLocation =
                CLLocation(
                    latitude: stop.latitude,
                    longitude: stop.longitude
                )

            let distance =
                userLocation.distance(
                    from: stopLocation
                )

            distanceByStopId[stop.id] =
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
