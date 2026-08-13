//
//  RouteEntity.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import Foundation
import SwiftData

@Model
final class RouteEntity {

    @Attribute(.unique)
    var id: String

    var number: String

    var originEnglish: String
    var originTraditional: String
    var originSimplified: String

    var destinationEnglish: String
    var destinationTraditional: String
    var destinationSimplified: String

    @Relationship(inverse: \OperatorEntity.routes)
    var operators: [OperatorEntity] = []

    var journeys: [JourneyEntity] = []

    init(
        id: String,
        number: String,
        originEnglish: String,
        originTraditional: String,
        originSimplified: String,
        destinationEnglish: String,
        destinationTraditional: String,
        destinationSimplified: String
    ) {
        self.id = id
        self.number = number

        self.originEnglish = originEnglish
        self.originTraditional = originTraditional
        self.originSimplified = originSimplified

        self.destinationEnglish = destinationEnglish
        self.destinationTraditional = destinationTraditional
        self.destinationSimplified = destinationSimplified
    }
}
