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

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    @Query
    private var operatorStopReferences:
        [OperatorStopReferenceEntity]

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
    private var isRefreshing = false

    @State
    private var nearbyRefreshID = 0

    @AppStorage(OperatorSelectionPreference.storageKey)
    private var selectedOperatorIdsValue = ""

    private var selectedOperatorIds: Set<String> {
        OperatorSelectionPreference.ids(
            from: selectedOperatorIdsValue
        )
    }

    private var isLocationAccessDenied: Bool {
        let status =
            locationManager.authorizationStatus

        return status == .denied ||
            status == .restricted
    }

    var body: some View {

        NavigationStack {

            Group {

                if isLocationAccessDenied {

                    CustomCardView(
                        imageIcon: "location.slash",
                        title: "Location Access Required",
                        subTitle: "Allow location access in Settings to find nearby routes.",
                        animated: false
                    )

                } else if isLoadingNearbyRoutes {

                    ProgressView(
                        "Finding nearby routes..."
                    )

                } else if locationManager.location == nil {

                    CustomCardView(
                        imageIcon: "location",
                        title: "Finding your location",
                        subTitle: "TransitGo uses your location to find nearby routes and arrival times.",
                        animated: true
                    )

                } else if nearbyMatches.isEmpty {

                    CustomCardView(
                        imageIcon: "bus.fill",
                        title: "No Nearby Routes",
                        subTitle: "No nearby routes were found for the current location",
                        animated: false
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

                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button {
                        refreshNearbyRoutes()
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                    .accessibilityLabel("Refresh nearby routes")
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

            isRefreshing = false
            
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

        guard !selectedOperatorIds.isEmpty else {
            return sortedNearbyMatches
        }

        return sortedNearbyMatches.filter {
            match in

            operatorIds(
                for: match.route
            )
            .isDisjoint(with: selectedOperatorIds) == false
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
                selectedOperatorIdsValue = ""
            } label: {

                if selectedOperatorIds.isEmpty {
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
                    toggleOperator(operatorId)
                } label: {

                    if selectedOperatorIds.contains(operatorId) {

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
                    selectedOperatorIds.isEmpty
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

    private func toggleOperator(_ operatorId: String) {
        var selection = selectedOperatorIds

        if selection.contains(operatorId) {
            selection.remove(operatorId)
        } else {
            selection.insert(operatorId)
        }

        selectedOperatorIdsValue =
            OperatorSelectionPreference.value(
                from: selection
            )
    }

    // MARK: - Nearby List

    private var nearbyList: some View {

        List {
            Section {
                ForEach(
                    filteredNearbyMatches,
                    id: \.journey.id
                ) { match in

                    NavigationLink {

                        RouteDetailView(
                            route: match.route
                        )

                    } label: {

                        RouteRowView(
                            route: match.route,
                            destination:
                                match.journey
                                    .destinationStop?
                                    .displayName(for: transitLanguage),
                            etaResult:
                                etaResults[
                                    match.journey.id
                                ]
                        )
                        .task(id: nearbyRefreshID) {
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
                operatorStopReferences:
                    operatorStopReferences,
                userLocation: userLocation,
                maximumDistanceMeters: 400,
                maximumRoutes: 50
            )
        
        isLoadingNearbyRoutes = false

        etaResults = [:]
        loadingRouteIds = []
        nearbyRefreshID += 1

    }

    @MainActor
    private func refreshNearbyRoutes() {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true

        if let location = locationManager.location {
            loadNearbyRoutes(
                userLocation: location
            )
        }

        locationManager.requestLocation()
    }

    // MARK: - Route ETA

    @MainActor
    private func loadETA(
        for match: NearbyRouteMatch,
        userLocation: CLLocation
    ) {

        let journeyId =
            match.journey.id

        guard
            etaResults[journeyId] == nil,
            !loadingRouteIds.contains(journeyId)
        else {
            return
        }

        loadingRouteIds.insert(
            journeyId
        )

        Task {

            defer {
                loadingRouteIds.remove(
                    journeyId
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
                    etaResults[journeyId] =
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
