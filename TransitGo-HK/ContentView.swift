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
    private var selectedTab: AppTab

    @AppStorage("appLanguage")
    private var selectedLanguage = TransitLanguage.english.rawValue

    @AppStorage(AppAppearance.storageKey)
    private var selectedAppearance = AppAppearance.system.rawValue

    private var appLanguage: TransitLanguage {
        TransitLanguage(
            preferenceValue: selectedLanguage
        )
    }

    private var datasetLoadErrorDescription: String {
        switch appLanguage {
        case .english:
            "Unable to prepare the transit dataset. Please try again."
        case .traditionalChinese:
            "未能準備交通資料集，請再試一次。"
        case .simplifiedChinese:
            "无法准备交通数据集，请重试。"
        }
    }

    init() {
        let storedValue = UserDefaults.standard.string(
            forKey: DefaultAppTab.storageKey
        )
        let defaultTab = DefaultAppTab(
            rawValue: storedValue ?? ""
        ) ?? .nearby

        _selectedTab = State(
            initialValue: defaultTab.appTab
        )
    }

    var body: some View {

        Group {

            if bootstrapFinished {

                TabView(selection: $selectedTab) {
                    Tab(value: .favorites) {
                        NavigationStack {
                            RouteFavoritesView(
                                isFavoritesActive:
                                    selectedTab == .favorites
                            )
                        }
                    } label: {
                        Label(
                            "Favorites",
                            systemImage: "bookmark"
                        )
                        .symbolVariant(.none)
                    }

                    Tab(
                        "Nearby",
                        systemImage: "location.fill",
                        value: .nearby
                    ) {
                        NearbyRouteListView(
                            isNearbyTabSelected:
                                selectedTab == .nearby
                        )
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
                        "More",
                        systemImage: "ellipsis.circle",
                        value: .more
                    ) {
                        MoreView()
                    }
                }
                .toolbarBackground(
                    .automatic,
                    for: .tabBar
                )

            } else if bootstrapError != nil {

                CustomCardView(
                    imageIcon: "exclamationmark.triangle",
                    title: "Dataset Error",
                    subTitle: datasetLoadErrorDescription,
                    animated: true
                )

            } else {

                ProgressView("Preparing TransitGo...")
            }
        }
        .environment(
            \.transitLanguage,
            appLanguage
        )
        .environment(\.locale, appLanguage.locale)
        .preferredColorScheme(
            AppAppearance(rawValue: selectedAppearance)?
                .colorScheme
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

enum AppTab: String, Hashable {
    case favorites
    case nearby
    case search
    case more
}
