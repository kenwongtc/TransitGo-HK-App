//
//  TransitETA.swift
//  TransitGo-HK
//
//  Created by Ken on 13/8/2026.
//

import Foundation

struct TransitETA: Identifiable {

    let operatorId: String
    let routeNumber: String

    let destinationTraditional: String
    let destinationSimplified: String
    let destinationEnglish: String

    let estimatedArrival: Date?

    let sequence: Int

    let remarkTraditional: String
    let remarkSimplified: String
    let remarkEnglish: String

    var id: String {
        [
            operatorId,
            routeNumber,
            String(sequence),
            estimatedArrival?.ISO8601Format() ?? "nil"
        ]
        .joined(separator: "|")
    }
}
