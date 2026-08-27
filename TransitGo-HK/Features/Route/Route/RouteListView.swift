//
//  RouteListView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//

import SwiftUI
import SwiftData

struct RouteListView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    let isSearchTabSelected: Bool

    init(isSearchTabSelected: Bool = true) {
        self.isSearchTabSelected = isSearchTabSelected
    }

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    @State
    private var searchText = ""

    @State
    private var isCustomKeyboardVisible =
        false

    @State
    private var enabledKeyboardKeys:
        Set<String> = []

    @State
    private var searchRecords: [RouteSearchRecord] = []

    @State
    private var routePrefixIndex:
        [String: [RouteSearchRecord]] = [:]

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

    private var filteredRoutes: [RouteEntity] {
        let query = searchText.uppercased()
        let records = routePrefixIndex[query] ?? []
        let isExactRouteNumber = records.contains {
            $0.routeNumber == query
        }
        let operatorIds = isExactRouteNumber &&
            narrowedOperatorIds.isEmpty
            ? nil
            : effectiveOperatorIds

        return records
            .compactMap { record in
                if let operatorIds,
                   !record.operatorIds.isSubset(
                        of: operatorIds
                   ) {
                    return nil
                }

                return record.route
            }
    }

    private var allOperatorIds:
        [String] {

        Array(
            Set(
                searchRecords.flatMap {
                    $0.operatorIds
                }
            )
        )
        .sorted()
    }

    private var searchResults: [RouteDirectionSearchResult] {
        var seenDirectionKeys: Set<String> = []

        return filteredRoutes.flatMap { route in
            route.journeys
                .sorted { $0.direction < $1.direction }
                .compactMap { journey in
                    guard
                        let origin = journey.originStop,
                        let destination = journey.destinationStop
                    else {
                        return nil
                    }

                    let key = [
                        route.id,
                        origin.id,
                        destination.id
                    ]
                    .joined(separator: "|")

                    guard seenDirectionKeys.insert(key).inserted else {
                        return nil
                    }

                    return RouteDirectionSearchResult(
                        route: route,
                        journey: journey,
                        origin: origin,
                        destination: destination
                    )
                }
        }
    }

    var body: some View {
        let displayedResults = searchResults

        NavigationStack {

            VStack(spacing: 0) {

                if displayedResults.isEmpty {

                    CustomCardView(
                        imageIcon: "magnifyingglass",
                        title: "No Routes Found",
                        subTitle: "Try another route number or operator.",
                        animated: true
                    )

                } else {

                    List(displayedResults) { result in
                        NavigationLink {
                            RouteDetailView(route: result.route)
                        } label: {
                            RouteRowView(
                                route: result.route,
                                origin: result.origin.displayName(
                                    for: transitLanguage
                                ),
                                destination:
                                    result.destination.displayName(
                                        for: transitLanguage
                                    ),
                                etaResult: nil,
                                isCompact: true,
                                allowsTwoLineOrigin: true,
                                allowsTwoLineDestination: true
                            )
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
            .onChange(of: isSearchTabSelected) {
                _, isSelected in

                guard isSelected else {
                    return
                }

                searchText = ""

                withAnimation {
                    isCustomKeyboardVisible = true
                }

                refreshEnabledKeyboardKeys()
            }
            .onChange(of: isCustomKeyboardVisible) {
                _, _ in
                refreshEnabledKeyboardKeys()
            }
            .onChange(of: searchText) {
                _, _ in
                refreshEnabledKeyboardKeys()
            }
            .onChange(of: selectedOperatorIdsValue) {
                _, _ in
                narrowedOperatorIds.formIntersection(
                    allowedOperatorIds
                )
                refreshEnabledKeyboardKeys()
            }
            .onChange(of: routes.count) {
                _, _ in
                refreshSearchIndex()
            }
            .task {
                refreshSearchIndex()
            }
        }
    }

    // MARK: - Keyboard

    private func refreshEnabledKeyboardKeys() {

        guard
            isSearchTabSelected,
            isCustomKeyboardVisible
        else {
            enabledKeyboardKeys = []
            return
        }

        let validKeys = Set(
            Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                .map(String.init)
        )

        let query = searchText.uppercased()

        var nextKeys: Set<String> = []

        for record in routePrefixIndex[query] ?? [] {
            guard record.operatorIds
                .isSubset(of: effectiveOperatorIds)
            else {
                continue
            }

            let routeNumber = record.routeNumber

            guard query.count < routeNumber.count else {
                continue
            }

            let keyIndex = routeNumber.index(
                routeNumber.startIndex,
                offsetBy: query.count
            )
            let key = String(routeNumber[keyIndex])

            if validKeys.contains(key) {
                nextKeys.insert(key)
            }
        }

        enabledKeyboardKeys = nextKeys
    }

    @MainActor
    private func refreshSearchIndex() {
        let records = routes.map { route in
            RouteSearchRecord(
                route: route,
                routeNumber: route.number.uppercased(),
                operatorIds: operatorIds(for: route)
            )
        }

        var prefixIndex: [String: [RouteSearchRecord]] = [
            "": records
        ]

        for record in records {
            var prefix = ""

            for character in record.routeNumber {
                prefix.append(character)
                prefixIndex[prefix, default: []]
                    .append(record)
            }
        }

        searchRecords = records
        routePrefixIndex = prefixIndex
        refreshEnabledKeyboardKeys()
    }

    // MARK: - Operator Filter

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
        refreshEnabledKeyboardKeys()
    }

}

private struct RouteDirectionSearchResult: Identifiable {
    let route: RouteEntity
    let journey: JourneyEntity
    let origin: StopEntity
    let destination: StopEntity

    var id: String { journey.id }
}

private struct RouteSearchRecord: Identifiable {
    let route: RouteEntity
    let routeNumber: String
    let operatorIds: Set<String>

    var id: String { route.id }
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
