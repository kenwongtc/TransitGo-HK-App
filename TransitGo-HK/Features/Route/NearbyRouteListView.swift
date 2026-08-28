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

    let isNearbyTabSelected: Bool

    init(isNearbyTabSelected: Bool = true) {
        self.isNearbyTabSelected = isNearbyTabSelected
    }

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    @Query
    private var operatorStopReferences:
        [OperatorStopReferenceEntity]

    @Environment(AppLocationManager.self)
    private var locationManager

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
    private var nearbyRefreshID = 0

    @State
    private var nearbyRouteIndex: NearbyRouteIndex?

    @State
    private var nearbyMatchesByJourneyStopId:
        [String: NearbyRouteMatch] = [:]

    @State
    private var nearbyLoadTask: Task<Void, Never>?

    @State
    private var nearbyLoadRequestID = 0

    @State
    private var lastResolvedLocation: CLLocation?

    @AppStorage(OperatorSelectionPreference.storageKey)
    private var selectedOperatorIdsValue = ""

    @State
    private var narrowedOperatorIds: Set<String> = []

    private var settingsOperatorIds: Set<String> {
        OperatorSelectionPreference.ids(
            from: selectedOperatorIdsValue
        )
    }

    private var allowedOperatorIds: Set<String> {
        settingsOperatorIds.isEmpty
            ? Set(allOperatorIds)
            : settingsOperatorIds
    }

    private var effectiveOperatorIds: Set<String> {
        narrowedOperatorIds.isEmpty
            ? allowedOperatorIds
            : narrowedOperatorIds
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

                    CustomCardView(
                        imageIcon: "location.fill",
                        title: "Finding nearby routes...",
                        subTitle: "TransitGo is checking routes near your current location.",
                        animated: true
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
            guard isNearbyTabSelected else {
                return
            }

            locationManager.requestLocation()

            if let cachedLocation =
                locationManager.location {
                loadNearbyRoutes(
                    userLocation: cachedLocation
                )
            }
        }
        .onChange(
            of: locationManager.location
        ) { _, newLocation in

            guard
                isNearbyTabSelected,
                let location =
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

            invalidateNearbyRouteIndex()

            guard let location =
                locationManager.location
            else {
                return
            }

            loadNearbyRoutes(
                userLocation: location,
                force: true
            )
        }
        .onChange(
            of: operatorStopReferences.count
        ) { _, _ in

            invalidateNearbyRouteIndex()

            guard let location =
                locationManager.location
            else {
                return
            }

            loadNearbyRoutes(
                userLocation: location,
                force: true
            )
        }
        .onChange(of: selectedOperatorIdsValue) {
            _, _ in
            narrowedOperatorIds.formIntersection(
                allowedOperatorIds
            )
        }
        .onChange(of: isNearbyTabSelected) {
            _, isSelected in

            if isSelected {
                refreshNearbyRoutes()
            } else {
                nearbyLoadTask?.cancel()
            }
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

        return sortedNearbyMatches.filter {
            match in

            !operatorIds(
                for: match.route
            )
            .isDisjoint(with: effectiveOperatorIds)
        }
    }

    private var allOperatorIds:
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
                narrowedOperatorIds = []
            } label: {

                if narrowedOperatorIds.isEmpty {
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
                allowedOperatorIds.sorted(),
                id: \.self
            ) { operatorId in

                Button {
                    toggleOperator(operatorId)
                } label: {

                    if narrowedOperatorIds.contains(operatorId) {

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
                    narrowedOperatorIds.isEmpty
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
        var selection = narrowedOperatorIds

        if selection.contains(operatorId) {
            selection.remove(operatorId)
        } else {
            selection.insert(operatorId)
        }

        narrowedOperatorIds = selection
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
                            stopName:
                                match.stop.displayName(
                                    for: transitLanguage
                                ),
                            stopCode: match.journeyStop.publicStopCode,
                            etaResult:
                                etaResults[
                                    match.journey.id
                                ]
                        )
                        .task(
                            id: "\(nearbyRefreshID)|\(isNearbyTabSelected)"
                        ) {
                            guard isNearbyTabSelected else {
                                return
                            }

                            guard let userLocation =
                                locationManager.location
                            else {
                                return
                            }

                            while !Task.isCancelled {
                                await loadETA(
                                    for: match,
                                    userLocation: userLocation,
                                    forceRefresh:
                                        etaResults[
                                            match.journey.id
                                        ] != nil
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
                }

            }
        }
        .listStyle(.plain)
        .refreshable {
            refreshNearbyRoutes(force: true)
        }
    }

    // MARK: - Load Nearby Routes

    private func loadNearbyRoutes(
        userLocation: CLLocation,
        force: Bool = false
    ) {

        guard !routes.isEmpty else {
            nearbyMatches = []
            etaResults = [:]
            return
        }

        if !force,
           let lastResolvedLocation,
           nearbyRouteIndex != nil {
            let movement = userLocation.distance(
                from: lastResolvedLocation
            )

            let accuracyImprovement =
                lastResolvedLocation.horizontalAccuracy
                - userLocation.horizontalAccuracy

            if movement < 10,
               accuracyImprovement < 10 {
                return
            }
        }

        lastResolvedLocation = userLocation

        nearbyLoadTask?.cancel()
        nearbyLoadRequestID += 1

        let requestID = nearbyLoadRequestID
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude

        isLoadingNearbyRoutes = true

        nearbyLoadTask = Task {
            await prepareNearbyRouteIndex()

            guard
                !Task.isCancelled,
                requestID == nearbyLoadRequestID,
                let nearbyRouteIndex
            else {
                return
            }

            let candidateResults = await Task.detached(
                priority: .userInitiated
            ) {
                nearbyRouteIndex.nearbyJourneyStops(
                    latitude: latitude,
                    longitude: longitude,
                    maximumDistanceMeters: 400,
                    maximumRoutes: 100
                )
            }
            .value

            guard
                !Task.isCancelled,
                requestID == nearbyLoadRequestID
            else {
                return
            }

            nearbyMatches = candidateResults.compactMap { result in
                guard let match =
                    nearbyMatchesByJourneyStopId[
                        result.journeyStopId
                    ]
                else {
                    return nil
                }

                return NearbyRouteMatch(
                    route: match.route,
                    journey: match.journey,
                    journeyStop: match.journeyStop,
                    stop: match.stop,
                    distanceMeters: result.distanceMeters
                )
            }

            isLoadingNearbyRoutes = false
            etaResults = [:]
            loadingRouteIds = []
            nearbyRefreshID += 1
        }

    }

    private func prepareNearbyRouteIndex() async {
        guard nearbyRouteIndex == nil else {
            return
        }

        let preparation = await NearbyRouteIndex.prepare(
            routes: routes,
            operatorStopReferences: operatorStopReferences
        )

        guard !Task.isCancelled else {
            return
        }

        nearbyRouteIndex = preparation.index
        nearbyMatchesByJourneyStopId =
            preparation.matchesByJourneyStopId
    }

    private func invalidateNearbyRouteIndex() {
        nearbyLoadTask?.cancel()
        nearbyRouteIndex = nil
        nearbyMatchesByJourneyStopId = [:]
    }

    @MainActor
    private func refreshNearbyRoutes(force: Bool = false) {
        if let location = locationManager.location {
            loadNearbyRoutes(
                userLocation: location,
                force: force
            )
        }

        locationManager.requestLocation()
    }

    // MARK: - Route ETA

    @MainActor
    private func loadETA(
        for match: NearbyRouteMatch,
        userLocation: CLLocation,
        forceRefresh: Bool = false
    ) async {

        let journeyId =
            match.journey.id

        guard
            forceRefresh || etaResults[journeyId] == nil,
            !loadingRouteIds.contains(journeyId)
        else {
            return
        }

        loadingRouteIds.insert(
            journeyId
        )

        let coordinator = ETARefreshCoordinator.shared
        await coordinator.acquire()

        guard !Task.isCancelled else {
            loadingRouteIds.remove(journeyId)
            await coordinator.release()
            return
        }

        do {
            let result =
                try await RouteETAResolver()
                    .resolve(
                        match: match,
                        modelContext:
                            modelContext
                    )

            if !Task.isCancelled,
                let result
            {
                etaResults[journeyId] = result
            }
        } catch {
        }

        loadingRouteIds.remove(journeyId)
        await coordinator.release()
    }
}

#Preview {

    NearbyRouteListView()
        .environment(AppLocationManager())
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
