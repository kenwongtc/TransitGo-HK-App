//
//  ContentView.swift
//  TransitGo-HK
//
//  Created by Ken on 10/8/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {

        RouteListView()
            .task {
                do {
                    let storage = DatasetStorage()
                    let reader = DatasetReader()

                    let referenceURL =
                        try storage.fileURL(
                            for: .operatorStopReferences
                        )

                    print(
                        "Operator reference file:",
                        referenceURL.path
                    )

                    print(
                        "Operator reference file exists:",
                        FileManager.default.fileExists(
                            atPath: referenceURL.path
                        )
                    )

                    let references =
                        try reader.decodeOperatorStopReferences(
                            from: referenceURL
                        )

                    print(
                        "Operator stop references decoded:",
                        references.count
                    )

                    if let knownReference =
                        references.first(where: {
                            $0.journeyId == "1200-1" &&
                            $0.sequence == 15 &&
                            $0.stopId == "9644"
                        }) {

                        print("*** Known KMB reference ***")
                        print(
                            "Journey:",
                            knownReference.journeyId
                        )
                        print(
                            "Sequence:",
                            knownReference.sequence
                        )
                        print(
                            "TransitGo stop:",
                            knownReference.stopId
                        )
                        print(
                            "KMB stop:",
                            knownReference.operatorStopId
                        )

                    } else {
                        print(
                            "Known KMB reference NOT FOUND"
                        )
                    }

                } catch {
                    print(
                        "Operator stop reference decode failed:",
                        error
                    )
                }
            }
    }
}
