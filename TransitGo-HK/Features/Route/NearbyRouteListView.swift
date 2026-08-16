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
            .navigationTitle("Nearby")
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

    // MARK: - Sort by ETA
    private var sortedNearbyMatches:
        [NearbyRouteMatch] {

        nearbyMatches.sorted { lhs, rhs in

            let lhsETA =
                nextETA(
                    for: lhs.route.id
                )

            let rhsETA =
                nextETA(
                    for: rhs.route.id
                )

            switch (lhsETA, rhsETA) {

            case let (lhsDate?, rhsDate?):

                if lhsDate != rhsDate {
                    return lhsDate < rhsDate
                }

                return lhs.distanceMeters <
                    rhs.distanceMeters

            case (.some, .none):

                return true

            case (.none, .some):

                return false

            case (.none, .none):

                return lhs.distanceMeters <
                    rhs.distanceMeters
            }
        }
    }

    private func nextETA(
        for routeId: String
    ) -> Date? {

        etaResults[routeId]?
            .etaRecords
            .compactMap {
                $0.estimatedArrival
            }
            .filter {
                $0 >= Date()
            }
            .min()
    }
    
    
    // MARK: - Nearby List

    private var nearbyList: some View {

        List {
            Section {
                ForEach(
                    sortedNearbyMatches,
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

                                if match.route.number == "10" {

                                    print(
                                        "ROUTE 10:",
                                        match.route.id,
                                        "|",
                                        match.route.originEnglish,
                                        "→",
                                        match.route.destinationEnglish
                                    )
                                }

                                loadETA(
                                    for: match,
                                    userLocation: userLocation
                                )
                            }
                        
                    }
                }

            } header: {

                Text("Nearby Routes")
            }
        }
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
                maximumRoutes: 100
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
