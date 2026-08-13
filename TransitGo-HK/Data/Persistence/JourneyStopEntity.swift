//
//  JourneyStopEntity.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import Foundation
import SwiftData

@Model
final class JourneyStopEntity {

    @Attribute(.unique)
    var id: String

    var sequence: Int
    var stop: StopEntity?

    @Relationship(inverse: \JourneyEntity.journeyStops)
    var journey: JourneyEntity?
    
    init(
        id: String,
        sequence: Int
    ) {
        self.id = id
        self.sequence = sequence
    }
}
