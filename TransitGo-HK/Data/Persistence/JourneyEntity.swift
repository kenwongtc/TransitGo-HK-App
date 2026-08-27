//
//  JourneyEntity.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import Foundation
import SwiftData

@Model
final class JourneyEntity {

    @Attribute(.unique)
    var id: String

    var direction: String
    var serviceType: String
    var adultFullFareCents: Int?
    var scheduledDurationMinutes: Int?

    @Relationship(inverse: \RouteEntity.journeys)
    var route: RouteEntity?

    var originStop: StopEntity?
    var destinationStop: StopEntity?

    var journeyStops: [JourneyStopEntity] = []

    init(
        id: String,
        direction: String,
        serviceType: String,
        adultFullFareCents: Int? = nil,
        scheduledDurationMinutes: Int? = nil
    ) {
        self.id = id
        self.direction = direction
        self.serviceType = serviceType
        self.adultFullFareCents = adultFullFareCents
        self.scheduledDurationMinutes = scheduledDurationMinutes
    }
}
