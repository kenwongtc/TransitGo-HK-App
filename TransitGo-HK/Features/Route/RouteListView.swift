//
//  RouteListView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData
import CoreLocation

struct RouteListView: View {

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var etaResults: [String: RouteETAResult] = [:]
    
    @State
    private var locationManager = AppLocationManager()
    
    @State
    private var loadingRouteIds: Set<String> = []
    
    @State
    private var searchText = ""

    private var filteredRoutes: [RouteEntity] {
        guard !searchText.isEmpty else {
            return routes
        }

        return routes.filter { route in
            route.number.localizedCaseInsensitiveContains(
                searchText
            )
            ||
            route.operators.contains { operatorEntity in
                operatorEntity.nameEnglish
                    .localizedCaseInsensitiveContains(
                        searchText
                    )
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredRoutes) { route in

                NavigationLink {
                    RouteDetailView(route: route)
                } label: {
                    RouteRowView(
                        route: route,
                        etaResult: etaResults[route.id]
                    )
                    .task {
                        guard !searchText.isEmpty else {
                            return
                        }

                        guard let userLocation =
                            locationManager.location
                        else {
                            return
                        }

                        loadETA(
                            for: route,
                            userLocation: userLocation
                        )
                    }
                }
            }
            .navigationTitle("Routes")
            .searchable(
                text: $searchText,
                prompt: "Route or operator"
            )
            .task {
                locationManager.requestLocation()
            }
        }
    }
    
    @MainActor
    private func loadETA(
        for route: RouteEntity,
        userLocation: CLLocation
    ) {

        let routeId = route.id

        guard
            etaResults[routeId] == nil,
            !loadingRouteIds.contains(routeId)
        else {
            return
        }

        loadingRouteIds.insert(routeId)

        Task {

            defer {
                loadingRouteIds.remove(routeId)
            }

            do {
                let result =
                    try await RouteETAResolver()
                        .resolve(
                            route: route,
                            userLocation: userLocation,
                            modelContext: modelContext
                        )

                if let result {
                    etaResults[routeId] = result
                }

            } catch {
                print(
                    "Search ETA load failed for route",
                    route.number,
                    ":",
                    error
                )
            }
        }
    }
}



#Preview {
    RouteListView()
        .modelContainer(
            for: [
                OperatorEntity.self,
                RouteEntity.self
            ],
            inMemory: true
        )
}
