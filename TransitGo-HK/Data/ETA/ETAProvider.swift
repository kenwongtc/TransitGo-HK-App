//
//  ETAProvider.swift
//  TransitGo-HK
//
//  Created by Ken on 13/8/2026.
//

import Foundation

enum ETAProviderError: Error {
    case unsupportedOperator(String)
    case invalidOperatorServiceType(String)
}

struct ETAProvider {

    private let kmbService =
        KMBETAService()

    func fetchETA(
        reference: OperatorStopReferenceEntity,
        routeNumber: String,
        bound: String?
    ) async throws -> [TransitETA] {

        switch reference.operatorId {

        case "KMB", "LWB":

            return try await fetchKMBETA(
                reference: reference,
                routeNumber: routeNumber,
                bound: bound
            )

        default:

            throw ETAProviderError
                .unsupportedOperator(
                    reference.operatorId
                )
        }
    }

    // MARK: - KMB / LWB

    private func fetchKMBETA(
        reference: OperatorStopReferenceEntity,
        routeNumber: String,
        bound: String?
    ) async throws -> [TransitETA] {

        guard
            let serviceType =
                Int(reference.operatorServiceType)
        else {

            throw ETAProviderError
                .invalidOperatorServiceType(
                    reference.operatorServiceType
                )
        }

        let records =
            try await kmbService.fetchETA(
                stopId:
                    reference.operatorStopId,
                route:
                    routeNumber,
                serviceType:
                    serviceType
            )

        let filteredRecords: [KMBETA]

        if let bound {

            filteredRecords =
                records.filter {
                    $0.dir == bound
                }

        } else {

            filteredRecords =
                records
        }

        return filteredRecords.map {

            makeTransitETA(
                from: $0,
                operatorId:
                    reference.operatorId
            )
        }
    }

    private func makeTransitETA(
        from source: KMBETA,
        operatorId: String
    ) -> TransitETA {

        let formatter =
            ISO8601DateFormatter()

        let estimatedArrival =
            source.eta.flatMap {
                formatter.date(from: $0)
            }

        return TransitETA(
            operatorId:
                operatorId,
            routeNumber:
                source.route,
            destinationTraditional:
                source.destTC,
            destinationSimplified:
                source.destSC,
            destinationEnglish:
                source.destEN,
            estimatedArrival:
                estimatedArrival,
            sequence:
                source.etaSeq,
            remarkTraditional:
                source.rmkTC,
            remarkSimplified:
                source.rmkSC,
            remarkEnglish:
                source.rmkEN
        )
    }
}
