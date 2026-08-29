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

    @State
    private var favoritesNavigationID = 0

    @State
    private var nearbyNavigationID = 0

    @State
    private var searchNavigationID = 0

    @State
    private var moreNavigationID = 0

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

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab {
                    resetNavigation(for: newTab)
                } else {
                    selectedTab = newTab
                }
            }
        )
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

                TabView(selection: tabSelection) {
                    Tab(value: .favorites) {
                        NavigationStack {
                            RouteFavoritesView(
                                isFavoritesActive:
                                    selectedTab == .favorites
                            )
                        }
                        .id(favoritesNavigationID)
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
                        .id(nearbyNavigationID)
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
                        .id(searchNavigationID)
                    }

                    Tab(
                        "More",
                        systemImage: "ellipsis.circle",
                        value: .more
                    ) {
                        MoreView()
                            .id(moreNavigationID)
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

    private func resetNavigation(for tab: AppTab) {
        switch tab {
        case .favorites:
            favoritesNavigationID += 1
        case .nearby:
            nearbyNavigationID += 1
        case .search:
            searchNavigationID += 1
        case .more:
            moreNavigationID += 1
        }
    }

}

enum AppTab: String, Hashable {
    case favorites
    case nearby
    case search
    case more
}
