//
//  RouteFavoritesView.swift
//  TransitGo-HK
//
//  Created by Ken on 22/8/2026.
//

import SwiftUI
import SwiftData
import CoreLocation

struct RouteFavoritesView: View {

    let isFavoritesActive: Bool

    init(isFavoritesActive: Bool = true) {
        self.isFavoritesActive = isFavoritesActive
    }

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Environment(\.modelContext)
    private var modelContext

    @AppStorage("favoriteRouteIds")
    private var favoriteRouteIdsValue = ""

    @AppStorage("favoriteStopIds")
    private var favoriteStopIdsValue = ""

    @State
    private var selection: FavoriteType = .routes

    @State
    private var favoriteStops: [StopEntity] = []

    @State
    private var favoriteRoutes: [RouteEntity] = []

    @State
    private var etaResults: [String: RouteETAResult] = [:]

    @State
    private var loadingRouteIds: Set<String> = []

    @Environment(AppLocationManager.self)
    private var locationManager

    private var favoriteRouteIds: Set<String> {
        storedIds(from: favoriteRouteIdsValue)
    }

    private var favoriteStopIds: Set<String> {
        storedIds(from: favoriteStopIdsValue)
    }

    private var navigationTitle: String {
        switch transitLanguage {
        case .english:
            "Favorites"
        case .traditionalChinese, .simplifiedChinese:
            "收藏"
        }
    }

    var body: some View {
        ZStack {
            CustomAppBackgroundView()

            VStack(spacing: 0) {
                Picker(
                    "Favorite Type",
                    selection: $selection
                ) {
                    ForEach(FavoriteType.allCases) { type in
                        Text(LocalizedStringKey(type.title))
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                switch selection {
                case .routes:
                    favoriteRoutesContent
                case .stops:
                    favoriteStopsContent
                }
            }
        }
        .navigationTitle(
            navigationTitle
        )
        .task(id: favoriteStopIdsValue) {
            loadFavoriteStops()
        }
        .task(id: favoriteRouteIdsValue) {
            loadFavoriteRoutes()

            if isFavoritesActive {
                locationManager.requestLocation()
            }
        }
        .onChange(of: isFavoritesActive) {
            _, isActive in

            if isActive {
                locationManager.requestLocation()
            }
        }
    }

    @ViewBuilder
    private var favoriteRoutesContent: some View {
        if favoriteRoutes.isEmpty {
            CustomCardView(
                imageIcon: "bookmark",
                title: "No Favorite Routes",
                subTitle: "Routes you save will appear here.",
                animated: false
            )
        } else {
            List(favoriteRoutes) { route in
                NavigationLink {
                    RouteDetailView(route: route)
                } label: {
                    RouteRowView(
                        route: route,
                        etaResult: etaResults[route.id],
                        isCompact: true
                    )
                    .environment(
                        \.locale,
                        transitLanguage.locale
                    )
                    .task(
                        id: etaTaskID(for: route)
                    ) {
                        guard
                            isFavoritesActive,
                            let userLocation =
                                locationManager.location
                        else {
                            return
                        }

                        while !Task.isCancelled {
                            await loadETA(
                                for: route,
                                userLocation: userLocation,
                                forceRefresh:
                                    etaResults[route.id] != nil
                            )

                            do {
                                try await Task.sleep(
                                    for: ETARefreshCoordinator
                                        .refreshInterval
                                )
                            } catch {
                                return
                            }
                        }
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        removeRoute(route.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var favoriteStopsContent: some View {
        if favoriteStops.isEmpty {
            CustomCardView(
                imageIcon: "mappin.and.ellipse",
                title: "No Favorite Stops",
                subTitle: "Stops you save will appear here.",
                animated: false
            )
        } else {
            List(favoriteStops) { stop in
                NavigationLink {
                    FavoriteStopDetailView(stop: stop)
                } label: {
                    Label {
                        Text(
                            stop.displayName(
                                for: transitLanguage
                            )
                        )
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        removeStop(stop.id)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func storedIds(from value: String) -> Set<String> {
        Set(
            value.split(separator: "\n")
                .map(String.init)
        )
    }

    private func removeRoute(_ id: String) {
        var ids = favoriteRouteIds
        ids.remove(id)
        favoriteRouteIdsValue = ids.sorted()
            .joined(separator: "\n")
    }

    private func removeStop(_ id: String) {
        var ids = favoriteStopIds
        ids.remove(id)
        favoriteStopIdsValue = ids.sorted()
            .joined(separator: "\n")
    }

    private func etaTaskID(for route: RouteEntity) -> String {
        let timestamp = locationManager.location?
            .timestamp.timeIntervalSince1970 ?? 0

        return "\(route.id)|\(timestamp)|\(isFavoritesActive)"
    }

    @MainActor
    private func loadFavoriteRoutes() {
        favoriteRoutes = favoriteRouteIds.compactMap { id in
            let favoriteId = id
            var descriptor = FetchDescriptor<RouteEntity>(
                predicate: #Predicate {
                    $0.id == favoriteId
                }
            )
            descriptor.fetchLimit = 1

            return try? modelContext.fetch(descriptor).first
        }
        .compactMap { $0 }
        .sorted {
            $0.number.localizedStandardCompare($1.number)
                == .orderedAscending
        }

        let loadedIds = Set(favoriteRoutes.map(\.id))
        etaResults = etaResults.filter {
            loadedIds.contains($0.key)
        }
        loadingRouteIds.formIntersection(loadedIds)
    }

    @MainActor
    private func loadFavoriteStops() {
        favoriteStops = favoriteStopIds.compactMap { id in
            let favoriteId = id
            var descriptor = FetchDescriptor<StopEntity>(
                predicate: #Predicate {
                    $0.id == favoriteId
                }
            )
            descriptor.fetchLimit = 1

            return try? modelContext.fetch(descriptor).first
        }
        .compactMap { $0 }
        .sorted {
            $0.displayName(for: transitLanguage)
                .localizedStandardCompare(
                    $1.displayName(for: transitLanguage)
                ) == .orderedAscending
        }
    }

    @MainActor
    private func loadETA(
        for route: RouteEntity,
        userLocation: CLLocation,
        forceRefresh: Bool
    ) async {
        let routeId = route.id

        guard
            forceRefresh || etaResults[routeId] == nil,
            !loadingRouteIds.contains(routeId)
        else {
            return
        }

        loadingRouteIds.insert(routeId)

        let coordinator = ETARefreshCoordinator.shared
        await coordinator.acquire()

        guard !Task.isCancelled else {
            loadingRouteIds.remove(routeId)
            await coordinator.release()
            return
        }

        do {
            let result = try await RouteETAResolver().resolve(
                route: route,
                userLocation: userLocation,
                modelContext: modelContext
            )

            if !Task.isCancelled, let result {
                etaResults[routeId] = result
            }
        } catch {}

        loadingRouteIds.remove(routeId)
        await coordinator.release()
    }
}

private enum FavoriteType: CaseIterable, Identifiable {
    case routes
    case stops

    var id: Self { self }

    var title: String {
        switch self {
        case .routes:
            "Routes"
        case .stops:
            "Stops"
        }
    }
}

#Preview {
    NavigationStack {
        RouteFavoritesView()
    }
    .environment(AppLocationManager())
}
