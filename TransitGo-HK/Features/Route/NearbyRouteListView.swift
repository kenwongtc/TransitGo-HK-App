//
//  NearbyRouteListView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI
import SwiftData
import CoreLocation

struct NearbyRouteListView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    @State
    private var locationManager =
        AppLocationManager()

    @State
    private var nearbyMatches:
        [NearbyRouteMatch] = []

    @State
    private var etaResults:
        [String: RouteETAResult] = [:]

    @State
    private var loadingRouteIds:
        Set<String> = []

    @State
    private var isLoadingNearbyRoutes =
        false

    @State
    private var selectedOperatorId:
        String?

    var body: some View {

        NavigationStack {

            Group {

                if isLoadingNearbyRoutes {

                    ProgressView(
                        "Finding nearby routes..."
                    )

                } else if locationManager.location == nil {

                    CustomCardView(
                        imageIcon: "location",
                        title: "Finding your location",
                        subTitle: "TransitGo uses your location to find nearby routes and arrival times."
                    )

                } else if nearbyMatches.isEmpty {

                    CustomCardView(
                        imageIcon: "bus",
                        title: "No Nearby Routes",
                        subTitle: "No nearby routes were found for the current location"
                    )

                } else {

                    nearbyList
                }
            }
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    operatorFilterMenu
                }
            }
            .safeAreaInset(
                edge: .bottom,
                spacing: 0
            ) {

                Text(
                    "Data provided by data.gov.hk"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .task {
            locationManager.requestLocation()
        }
        .onChange(
            of: locationManager.location
        ) { _, newLocation in

            guard let location =
                newLocation
            else {
                return
            }

            loadNearbyRoutes(
                userLocation: location
            )
            
        }
        .onChange(
            of: routes.count
        ) { _, _ in

            guard let location =
                locationManager.location
            else {
                return
            }

            loadNearbyRoutes(
                userLocation: location
            )
        }
    }

    // MARK: - Sort by Distance, then Route

    private var sortedNearbyMatches:
        [NearbyRouteMatch] {

        nearbyMatches.sorted { lhs, rhs in

            if lhs.distanceMeters !=
                rhs.distanceMeters {

                return lhs.distanceMeters <
                    rhs.distanceMeters
            }

            let routeComparison =
                lhs.route.number
                    .localizedStandardCompare(
                        rhs.route.number
                    )

            if routeComparison != .orderedSame {
                return routeComparison ==
                    .orderedAscending
            }

            return lhs.route.id <
                rhs.route.id
        }
    }

    // MARK: - Operator Filter

    private var filteredNearbyMatches:
        [NearbyRouteMatch] {

        guard let selectedOperatorId else {
            return sortedNearbyMatches
        }

        return sortedNearbyMatches.filter {
            match in

            operatorIds(
                for: match.route
            )
            .contains(selectedOperatorId)
        }
    }

    private var availableOperatorIds:
        [String] {

        Array(
            Set(
                nearbyMatches.flatMap {
                    operatorIds(
                        for: $0.route
                    )
                }
            )
        )
        .sorted()
    }

    private var operatorFilterMenu:
        some View {

        Menu {

            Button {
                selectedOperatorId = nil
            } label: {

                if selectedOperatorId == nil {
                    Label(
                        "All Operators",
                        systemImage: "checkmark"
                    )
                } else {
                    Text("All Operators")
                }
            }

            Divider()

            ForEach(
                availableOperatorIds,
                id: \.self
            ) { operatorId in

                Button {
                    selectedOperatorId =
                        operatorId
                } label: {

                    if selectedOperatorId ==
                        operatorId {

                        Label(
                            operatorId,
                            systemImage: "checkmark"
                        )

                    } else {
                        Text(operatorId)
                    }
                }
            }

        } label: {

            Image(
                systemName:
                    selectedOperatorId == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .accessibilityLabel(
            "Filter by operator"
        )
    }

    private func operatorIds(
        for route: RouteEntity
    ) -> Set<String> {

        Set(
            route.operators.flatMap {
                $0.id.split(separator: "+")
                    .map(String.init)
            }
        )
    }

    // MARK: - Nearby List

    private var nearbyList: some View {

        List {
            Section {
                ForEach(
                    filteredNearbyMatches,
                    id: \.route.id
                ) { match in

                    NavigationLink {

                        RouteDetailView(
                            route: match.route
                        )

                    } label: {

                        RouteRowView(
                            route: match.route,
                            etaResult:
                                etaResults[
                                    match.route.id
                                ]
                        )
                        .task {
                                guard let userLocation =
                                    locationManager.location
                                else {
                                    return
                                }

                                loadETA(
                                    for: match,
                                    userLocation: userLocation
                                )
                            }
                        
                    }
                }

            }
        }
        .listStyle(.plain)
    }

    // MARK: - Load Nearby Routes

    @MainActor
    private func loadNearbyRoutes(
        userLocation: CLLocation
    ) {

        guard !routes.isEmpty else {
            nearbyMatches = []
            etaResults = [:]
            return
        }

        isLoadingNearbyRoutes = true

        let resolver = NearbyRouteResolver()

        nearbyMatches =
            resolver.nearbyRoutes(
                from: routes,
                userLocation: userLocation,
                maximumDistanceMeters: 250,
                maximumRoutes: 30
            )
        
        isLoadingNearbyRoutes = false

        etaResults = [:]
        loadingRouteIds = []

    }

    // MARK: - Route ETA

    @MainActor
    private func loadETA(
        for match: NearbyRouteMatch,
        userLocation: CLLocation
    ) {

        let routeId =
            match.route.id

        guard
            etaResults[routeId] == nil,
            !loadingRouteIds.contains(routeId)
        else {
            return
        }

        loadingRouteIds.insert(
            routeId
        )

        Task {

            defer {
                loadingRouteIds.remove(
                    routeId
                )
            }

            do {
                let result =
                    try await RouteETAResolver()
                        .resolve(
                            match: match,
                            modelContext:
                                modelContext
                        )

                if let result {
                    etaResults[routeId] =
                        result
                }

            } catch {
                print(
                    "ETA load failed for route",
                    match.route.number,
                    ":",
                    error
                )
            }
        }
    }
}

#Preview {

    NearbyRouteListView()
        .modelContainer(
            for: [
                OperatorEntity.self,
                RouteEntity.self,
                JourneyEntity.self,
                JourneyStopEntity.self,
                StopEntity.self,
                OperatorStopReferenceEntity.self
            ],
            inMemory: true
        )
}
