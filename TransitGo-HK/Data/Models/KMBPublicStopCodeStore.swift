//
//  KMBPublicStopCodeStore.swift
//  TransitGo-HK
//

import Foundation

enum KMBPublicStopCodeStore {
    private struct Payload: Decodable {
        let codes: [String: String]
        let journeyCodes: [String: String]
    }

    private static let codes: [String: String] = {
        payload?.codes ?? [:]
    }()

    private static let journeyCodes: [String: String] = {
        payload?.journeyCodes ?? [:]
    }()

    private static let payload: Payload? = {
        guard
            let url = Bundle.main.url(
                forResource: "kmb_public_stop_codes",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(
                Payload.self,
                from: data
            )
        else {
            return nil
        }

        return payload
    }()

    static func code(for operatorStopId: String) -> String? {
        codes[operatorStopId.uppercased()]
    }

    static func code(
        for journeyId: String,
        sequence: Int
    ) -> String? {
        journeyCodes["\(journeyId)|\(sequence)"]
    }
}
