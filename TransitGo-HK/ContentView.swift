//
//  ContentView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var bootstrapFinished = false

    @State
    private var bootstrapError: Error?

    @State
    private var selectedTab: AppTab = .nearby

    @AppStorage("appLanguage")
    private var selectedLanguage = TransitLanguage.english.rawValue

    var body: some View {

        Group {

            if bootstrapFinished {

                TabView(selection: $selectedTab) {

                    Tab(
                        "Favorites",
                        systemImage: "bookmark",
                        value: .favorites
                    ) {
                        RouteFavoritesView()
                    }

                    Tab(
                        "Nearby",
                        systemImage: "location.fill",
                        value: .nearby
                    ) {
                        NearbyRouteListView()
                    }

                    Tab(
                        "Search",
                        systemImage: "magnifyingglass",
                        value: .search
                    ) {
                        RouteListView(
                            isSearchTabSelected:
                                selectedTab == .search
                        )
                    }

                    Tab(
                        "Settings",
                        systemImage: "gearshape.2",
                        value: .settings
                    ) {
                        SettingsView()
                    }
                }

            } else if let bootstrapError {

                CustomCardView(
                    imageIcon: "exclamationmark.triangle",
                    title: "Dataset Error",
                    subTitle: bootstrapError.localizedDescription,
                    animated: true
                )

            } else {

                ProgressView("Preparing TransitGo...")
            }
        }
        .environment(
            \.transitLanguage,
            TransitLanguage(
                preferenceValue: selectedLanguage
            )
        )
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

private enum AppTab: Hashable {
    case favorites
    case nearby
    case search
    case settings
}
