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

    let isSearchTabSelected: Bool

    init(isSearchTabSelected: Bool = true) {
        self.isSearchTabSelected = isSearchTabSelected
    }

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

    @State
    private var isCustomKeyboardVisible =
        true

    @AppStorage(OperatorSelectionPreference.storageKey)
    private var selectedOperatorIdsValue = ""

    private var selectedOperatorIds: Set<String> {
        OperatorSelectionPreference.ids(
            from: selectedOperatorIdsValue
        )
    }

    private var filteredRoutes: [RouteEntity] {

        routes.filter { route in

            let matchesQuery =
                searchText.isEmpty ||
                route.number
                    .localizedCaseInsensitiveContains(
                        searchText
                    )

            let matchesOperator =
                selectedOperatorIds.isEmpty ||
                !operatorIds(for: route)
                    .isDisjoint(with: selectedOperatorIds)

            return matchesQuery &&
                matchesOperator
        }
    }

    private var availableOperatorIds:
        [String] {

        Array(
            Set(
                routes.flatMap {
                    operatorIds(for: $0)
                }
            )
        )
        .sorted()
    }

    private var enabledKeyboardKeys:
        Set<String> {

        let operatorFilteredRoutes =
            routes.filter { route in

                selectedOperatorIds.isEmpty ||
                    !operatorIds(for: route)
                        .isDisjoint(with: selectedOperatorIds)
            }

        let allKeys =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                .map(String.init)

        return Set(
            allKeys.filter { key in

                let candidate =
                    searchText + key

                return operatorFilteredRoutes
                    .contains { route in

                        route.number
                            .localizedCaseInsensitiveContains(
                                candidate
                            )
                    }
            }
        )
    }

    var body: some View {
        NavigationStack {

            VStack(spacing: 0) {

                if filteredRoutes.isEmpty {

                    CustomCardView(
                        imageIcon: "magnifyingglass",
                        title: "No Routes Found",
                        subTitle: "Try another route number or operator.",
                        animated: true
                    )

                } else {

                    List(filteredRoutes) { route in

                        NavigationLink {
                            RouteDetailView(route: route)
                        } label: {
                            RouteRowView(
                                route: route,
                                etaResult:
                                    etaResults[route.id],
                                isCompact: true
                            )
                            .task(
                                id: locationManager
                                    .location?
                                    .timestamp
                            ) {
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
                                    userLocation:
                                        userLocation
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                    .onScrollPhaseChange {
                        _, newPhase in

                        guard
                            newPhase.isScrolling,
                            isCustomKeyboardVisible
                        else {
                            return
                        }

                        withAnimation {
                            isCustomKeyboardVisible =
                                false
                        }
                    }
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
                        withAnimation {
                            isCustomKeyboardVisible
                                .toggle()
                        }
                    } label: {
                        Image(
                            systemName:
                                isCustomKeyboardVisible
                                ? "keyboard.chevron.compact.down"
                                : "keyboard"
                        )
                    }
                    .accessibilityLabel(
                        isCustomKeyboardVisible
                        ? "Hide route keyboard"
                        : "Show route keyboard"
                    )
                }
            }
            .safeAreaInset(
                edge: .bottom,
                spacing: 0
            ) {

                VStack(spacing: 0) {

                    Text(
                        "Data provided by data.gov.hk"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.vertical, 8)
                    .background(.bar)

                    if isCustomKeyboardVisible {

                        CustomRouteKeyboardView(
                            text: $searchText,
                            enabledKeys:
                                enabledKeyboardKeys
                        )
                        .transition(
                            .move(edge: .bottom)
                                .combined(
                                    with: .opacity
                                )
                        )
                    }
                }
            }
            .task {
                locationManager.requestLocation()
            }
            .onChange(of: isSearchTabSelected) {
                _, isSelected in

                guard isSelected else {
                    return
                }

                searchText = ""
                etaResults = [:]
                loadingRouteIds = []

                withAnimation {
                    isCustomKeyboardVisible = true
                }
            }
        }
    }

    // MARK: - Operator Filter

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

                    etaResults[routeId] =
                        result

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
