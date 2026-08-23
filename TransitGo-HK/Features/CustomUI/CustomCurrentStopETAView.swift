//
//  CustomCurrentStopETAView.swift
//  TransitGo-HK
//

import SwiftUI

struct CustomCurrentStopETAView: View {
    let directionName: String?
    let stopName: String?
    let etaResult: RouteETAResult?
    let isLoading: Bool
    let isUnavailable: Bool
    let didFail: Bool

    init(
        directionName: String? = nil,
        stopName: String?,
        etaResult: RouteETAResult?,
        isLoading: Bool,
        isUnavailable: Bool,
        didFail: Bool
    ) {
        self.directionName = directionName
        self.stopName = stopName
        self.etaResult = etaResult
        self.isLoading = isLoading
        self.isUnavailable = isUnavailable
        self.didFail = didFail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let stopName {
                if let directionName {
                    Text("Towards \(directionName)")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                }

                Text(stopName)
                    .font(.headline)

                etaContent
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)

                    Text("Finding nearest stop...")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    @ViewBuilder
    private var etaContent: some View {
        if isLoading {
            ProgressView("Loading arrivals...")
        } else if isUnavailable {
            statusText("ETA unavailable")
        } else if didFail {
            statusText("Unable to load ETA")
        } else if let etaResult {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let arrivals = etaResult.etaRecords
                    .compactMap(\.estimatedArrival)
                    .filter { $0 >= context.date }
                    .sorted()
                    .prefix(3)

                if arrivals.isEmpty {
                    statusText("No upcoming arrivals")
                } else {
                    VStack(spacing: 8) {
                        ForEach(
                            Array(arrivals.enumerated()),
                            id: \.offset
                        ) { _, arrival in
                            HStack {
                                Text("Next")
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(arrival, style: .relative)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        } else {
            statusText("Waiting for ETA...")
        }
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
    }
}
