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

                    ContentUnavailableView(
                        "Finding Your Location",
                        systemImage: "location",
                        description: Text(
                            "TransitGo uses your location to find nearby routes and arrival times."
                        )
                    )

                } else if nearbyMatches.isEmpty {

                    ContentUnavailableView(
                        "No Nearby Routes",
                        systemImage: "bus",
                        description: Text(
                            "No nearby routes were found for the current location."
                        )
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

    // MARK: - Nearby List

    private var nearbyList: some View {

        List {

            Section {

                ForEach(
                    nearbyMatches,
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

        let resolver =
            NearbyRouteResolver()

        nearbyMatches =
            resolver.nearbyRoutes(
                from: routes,
                userLocation: userLocation,
                limit: 20
            )
        
        
        if let b1Route =
            routes.first(where: {
                $0.number == "B1"
            }) {

            let allMatches =
                resolver.nearbyRoutes(
                    from: [b1Route],
                    userLocation: userLocation,
                    limit: 1
                )

            if let b1Match =
                allMatches.first {

                print(
                    "*** B1 geographic diagnostic ***"
                )

                print(
                    "Stop:",
                    b1Match.stop.nameEnglish
                )

                print(
                    "Distance:",
                    String(
                        format: "%.0f m",
                        b1Match.distanceMeters
                    )
                )
            } else {
                print(
                    "B1 has no geographic match"
                )
            }
        }
        
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
                            route: match.route,
                            userLocation:
                                userLocation,
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
