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

    @Relationship(inverse: \RouteEntity.journeys)
    var route: RouteEntity?

    var originStop: StopEntity?
    var destinationStop: StopEntity?

    var journeyStops: [JourneyStopEntity] = []

    init(
        id: String,
        direction: String,
        serviceType: String
    ) {
        self.id = id
        self.direction = direction
        self.serviceType = serviceType
    }
}
