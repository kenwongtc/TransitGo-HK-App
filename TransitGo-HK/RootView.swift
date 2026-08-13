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

    var body: some View {

        RouteListView()
            .task {
                do {
                    try await DatasetBootstrapper().bootstrap(
                        modelContext: modelContext
                    )

                    print("App bootstrap finished")

                } catch {
                    print(
                        "App bootstrap failed:",
                        error
                    )
                }
            }
    }
}
