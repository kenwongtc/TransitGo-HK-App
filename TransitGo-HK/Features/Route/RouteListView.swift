//
//  RouteListView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData

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
                }
            }
            .navigationTitle("Routes")
            .searchable(
                text: $searchText,
                prompt: "Route or operator"
            )
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
