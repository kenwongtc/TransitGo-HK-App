//
//  RootView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var bootstrapFinished = false

    @State
    private var bootstrapError: Error?

    var body: some View {

        Group {

            if bootstrapFinished {

                TabView {

                    Tab(
                        "Nearby",
                        systemImage: "location.fill"
                    ) {
                        NearbyRouteListView()
                    }

                    Tab(
                        "Search",
                        systemImage: "magnifyingglass"
                    ) {
                        RouteListView()
                    }
                }

            } else if let bootstrapError {

                ContentUnavailableView(
                    "Dataset Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(
                        bootstrapError.localizedDescription
                    )
                )

            } else {

                ProgressView(
                    "Preparing TransitGo..."
                )
            }
        }
        .task {

            guard !bootstrapFinished else {
                return
            }

            do {

                try await DatasetBootstrapper().bootstrap(
                    modelContext: modelContext
                )

                bootstrapFinished = true

            } catch {

                bootstrapError = error

                print(
                    "App bootstrap failed:",
                    error
                )
            }
        }
    }
}
