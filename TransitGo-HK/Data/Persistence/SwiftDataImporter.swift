//
//  SwiftDataImporter.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import Foundation
import SwiftData

@MainActor
struct SwiftDataImporter {

    // MARK: - Operators

    func importOperators(
        from sourceOperators: [TransitOperator],
        into modelContext: ModelContext
    ) throws {

        for source in sourceOperators {
            let sourceId = source.id

            let descriptor = FetchDescriptor<OperatorEntity>(
                predicate: #Predicate {
                    $0.id == sourceId
                }
            )

            let existing = try modelContext.fetch(descriptor)

            if existing.isEmpty {
                let entity = OperatorEntity(
                    id: source.id,
                    nameEnglish: source.nameEnglish,
                    nameSimplified: source.nameSimplified,
                    nameTraditional: source.nameTraditional
                )

                modelContext.insert(entity)
            }
        }

        try modelContext.save()
    }


    // MARK: - Routes

    func importRoutes(
        from sourceRoutes: [TransitRoute],
        into modelContext: ModelContext
    ) throws {

        let allOperators = try modelContext.fetch(
            FetchDescriptor<OperatorEntity>()
        )

        let operatorLookup = Dictionary(
            uniqueKeysWithValues: allOperators.map {
                ($0.id, $0)
            }
        )

        for source in sourceRoutes {

            let sourceId = source.id

            let descriptor = FetchDescriptor<RouteEntity>(
                predicate: #Predicate {
                    $0.id == sourceId
                }
            )

            let existing = try modelContext.fetch(descriptor)

            let route: RouteEntity

            if let existingRoute = existing.first {

                route = existingRoute

                route.number = source.number

                route.originEnglish = source.originEnglish
                route.originTraditional = source.originTraditional
                route.originSimplified = source.originSimplified

                route.destinationEnglish = source.destinationEnglish
                route.destinationTraditional = source.destinationTraditional
                route.destinationSimplified = source.destinationSimplified

            } else {

                route = RouteEntity(
                    id: source.id,
                    number: source.number,
                    originEnglish: source.originEnglish,
                    originTraditional: source.originTraditional,
                    originSimplified: source.originSimplified,
                    destinationEnglish: source.destinationEnglish,
                    destinationTraditional: source.destinationTraditional,
                    destinationSimplified: source.destinationSimplified
                )

                modelContext.insert(route)
            }

            route.operators = source.operatorIds.compactMap {
                operatorLookup[$0]
            }
        }

        try modelContext.save()
    }


    // MARK: - Stops

    func importStops(
        from sourceStops: [TransitStop],
        into modelContext: ModelContext
    ) throws {

        for source in sourceStops {

            let sourceId = source.id

            let descriptor = FetchDescriptor<StopEntity>(
                predicate: #Predicate {
                    $0.id == sourceId
                }
            )

            let existing = try modelContext.fetch(descriptor)

            if let stop = existing.first {

                stop.latitude = source.latitude
                stop.longitude = source.longitude
                stop.nameEnglish = source.nameEnglish
                stop.nameSimplified = source.nameSimplified
                stop.nameTraditional = source.nameTraditional
                stop.regionId = source.regionId
                stop.districtId = source.districtId

            } else {

                let stop = StopEntity(
                    id: source.id,
                    latitude: source.latitude,
                    longitude: source.longitude,
                    nameEnglish: source.nameEnglish,
                    nameSimplified: source.nameSimplified,
                    nameTraditional: source.nameTraditional,
                    regionId: source.regionId,
                    districtId: source.districtId
                )

                modelContext.insert(stop)
            }
        }

        try modelContext.save()
    }


    // MARK: - Journeys

    func importJourneys(
        from sourceJourneys: [TransitJourney],
        into modelContext: ModelContext
    ) throws {

        let routes = try modelContext.fetch(
            FetchDescriptor<RouteEntity>()
        )

        let stops = try modelContext.fetch(
            FetchDescriptor<StopEntity>()
        )

        let routeLookup = Dictionary(
            uniqueKeysWithValues: routes.map {
                ($0.id, $0)
            }
        )

        let stopLookup = Dictionary(
            uniqueKeysWithValues: stops.map {
                ($0.id, $0)
            }
        )

        for source in sourceJourneys {

            let sourceId = source.id

            let descriptor = FetchDescriptor<JourneyEntity>(
                predicate: #Predicate {
                    $0.id == sourceId
                }
            )

            let existing = try modelContext.fetch(descriptor)

            let journey: JourneyEntity

            if let existingJourney = existing.first {

                journey = existingJourney
                journey.direction = source.direction
                journey.serviceType = source.serviceType
                journey.adultFullFareCents =
                    source.adultFullFareCents
                journey.scheduledDurationMinutes =
                    source.scheduledDurationMinutes
                journey.sectionFareTiersData =
                    source.sectionFareTiers.flatMap {
                        try? JSONEncoder().encode($0)
                    }

            } else {

                journey = JourneyEntity(
                    id: source.id,
                    direction: source.direction,
                    serviceType: source.serviceType,
                    adultFullFareCents:
                        source.adultFullFareCents,
                    scheduledDurationMinutes:
                        source.scheduledDurationMinutes,
                    sectionFareTiers:
                        source.sectionFareTiers
                )

                modelContext.insert(journey)
            }

            journey.route = routeLookup[source.routeId]
            journey.originStop = stopLookup[source.originStopId]
            journey.destinationStop = stopLookup[source.destinationStopId]
        }

        try modelContext.save()
    }


    // MARK: - Journey Stops

    func importJourneyStops(
        from sourceJourneyStops: [TransitJourneyStop],
        into modelContext: ModelContext
    ) throws {

        let journeys = try modelContext.fetch(
            FetchDescriptor<JourneyEntity>()
        )

        let stops = try modelContext.fetch(
            FetchDescriptor<StopEntity>()
        )

        let existingJourneyStops = try modelContext.fetch(
            FetchDescriptor<JourneyStopEntity>()
        )

        let journeyLookup = Dictionary(
            uniqueKeysWithValues: journeys.map {
                ($0.id, $0)
            }
        )

        let stopLookup = Dictionary(
            uniqueKeysWithValues: stops.map {
                ($0.id, $0)
            }
        )

        var journeyStopLookup = Dictionary(
            uniqueKeysWithValues: existingJourneyStops.map {
                ($0.id, $0)
            }
        )

        for source in sourceJourneyStops {

            let entityId =
                "\(source.journeyId)|\(source.sequence)"

            let entity: JourneyStopEntity

            if let existing = journeyStopLookup[entityId] {

                entity = existing
                entity.sequence = source.sequence
                entity.stopPickDrop = source.stopPickDrop

            } else {

                entity = JourneyStopEntity(
                    id: entityId,
                    sequence: source.sequence,
                    stopPickDrop: source.stopPickDrop
                )

                modelContext.insert(entity)

                journeyStopLookup[entityId] = entity
            }

            entity.journey = journeyLookup[source.journeyId]
            entity.stop = stopLookup[source.stopId]
        }

        try modelContext.save()
    }


    // MARK: - Schedules

    func importSchedules(
        from sourceSchedules: [TransitSchedule],
        into modelContext: ModelContext
    ) throws {

        let journeys = try modelContext.fetch(
            FetchDescriptor<JourneyEntity>()
        )

        let journeyLookup = Dictionary(
            uniqueKeysWithValues: journeys.map {
                ($0.id, $0)
            }
        )

        let existingSchedules = try modelContext.fetch(
            FetchDescriptor<ScheduleEntity>()
        )

        var scheduleLookup = Dictionary(
            uniqueKeysWithValues: existingSchedules.map {
                ($0.id, $0)
            }
        )

        for source in sourceSchedules {

            let schedule: ScheduleEntity

            if let existing = scheduleLookup[source.id] {

                schedule = existing
                schedule.serviceType = source.serviceType
                schedule.departureTime = source.departureTime

            } else {

                schedule = ScheduleEntity(
                    id: source.id,
                    serviceType: source.serviceType,
                    departureTime: source.departureTime
                )

                modelContext.insert(schedule)

                scheduleLookup[source.id] = schedule
            }

            schedule.journey = journeyLookup[source.journeyId]
        }

        try modelContext.save()
    }
    
    // MARK: - Operator Stop References

    func importOperatorStopReferences(
        from sourceReferences: [TransitOperatorStopReference],
        into modelContext: ModelContext
    ) throws {

        // The operator-stop-reference JSON is a complete
        // snapshot of the current dataset.
        //
        // Remove references from the previous dataset
        // before importing the new snapshot.

        let existingReferences =
            try modelContext.fetch(
                FetchDescriptor<
                    OperatorStopReferenceEntity
                >()
            )

        for reference in existingReferences {
            modelContext.delete(reference)
        }

        try modelContext.save()

        // Import the current dataset snapshot.

        for source in sourceReferences {

            let publicStopCode = source.operatorId == "KMB"
                ? source.publicStopCode
                : nil

            let entity =
                OperatorStopReferenceEntity(
                    operatorId:
                        source.operatorId,
                    journeyId:
                        source.journeyId,
                    stopId:
                        source.stopId,
                    sequence:
                        source.sequence,
                    operatorStopId:
                        source.operatorStopId,
                    publicStopCode:
                        publicStopCode,
                    operatorLatitude:
                        source.operatorLatitude,
                    operatorLongitude:
                        source.operatorLongitude,
                    operatorServiceType:
                        source.operatorServiceType,
                    operatorDirection:
                        source.operatorDirection
                )

            modelContext.insert(entity)
        }

        let journeyStops = try modelContext.fetch(
            FetchDescriptor<JourneyStopEntity>()
        )

        let journeyStopLookup = Dictionary(
            uniqueKeysWithValues: journeyStops.map {
                ($0.id, $0)
            }
        )

        for journeyStop in journeyStops {
            journeyStop.publicStopCode = nil
        }

        for source in sourceReferences where source.operatorId == "KMB" {
            guard let publicStopCode = source.publicStopCode else {
                continue
            }

            journeyStopLookup[
                "\(source.journeyId)|\(source.sequence)"
            ]?.publicStopCode = publicStopCode
        }

        try modelContext.save()
    }
}
