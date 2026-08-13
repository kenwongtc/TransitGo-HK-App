//
//  TransitStop.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import Foundation

struct TransitStop: Codable {
    let id: String
    let latitude: Double
    let longitude: Double
    let nameEnglish: String
    let nameSimplified: String
    let nameTraditional: String
}
