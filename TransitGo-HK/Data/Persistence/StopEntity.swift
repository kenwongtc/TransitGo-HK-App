//
//  StopEntity.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import Foundation
import SwiftData

@Model
final class StopEntity {

    @Attribute(.unique)
    var id: String

    var latitude: Double
    var longitude: Double

    var nameEnglish: String
    var nameSimplified: String
    var nameTraditional: String

    init(
        id: String,
        latitude: Double,
        longitude: Double,
        nameEnglish: String,
        nameSimplified: String,
        nameTraditional: String
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.nameEnglish = nameEnglish
        self.nameSimplified = nameSimplified
        self.nameTraditional = nameTraditional
    }
}

extension StopEntity {

    var displayNameEnglish: String {
        sanitizedStopName(
            nameEnglish
        )
    }

    var displayNameSimplified: String {
        sanitizedStopName(
            nameSimplified
        )
    }

    var displayNameTraditional: String {
        sanitizedStopName(
            nameTraditional
        )
    }

    private func sanitizedStopName(
        _ value: String
    ) -> String {

        var result = value

        let breakVariants = [
            "/<br>",
            "/</br>",
            "<br>",
            "</br>",
            "<br/>",
            "<br />"
        ]

        for variant in breakVariants {

            result =
                result.replacingOccurrences(
                    of: variant,
                    with: " "
                )
        }

        return result
            .split {
                $0.isWhitespace
            }
            .joined(separator: " ")
    }
}
