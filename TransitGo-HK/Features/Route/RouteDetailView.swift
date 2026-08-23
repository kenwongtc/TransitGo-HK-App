//
//  RouteDetailView.swift
//  TransitGo-HK
//
//  Created by Ken on 17/8/2026.
//

import SwiftUI
import SwiftData
import CoreLocation

struct RouteDetailView: View {

    let route: RouteEntity

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.transitLanguage)
    private var transitLanguage

    @State
    private var selectedSection:
        RouteDetailSection = .routeDetails

    @State
    private var locationManager =
        AppLocationManager()

    @State
    private var currentStopETAResults:
        [String: RouteETAResult] = [:]

    @State
    private var loadingCurrentStopIds:
        Set<String> = []

    @State
    private var unavailableCurrentStopIds:
        Set<String> = []

    @State
    private var failedCurrentStopIds:
        Set<String> = []

    @AppStorage("favoriteRouteIds")
    private var favoriteRouteIdsValue = ""

    private var journeys: [JourneyEntity] {
        route.journeys.sorted {
            $0.direction < $1.direction
        }
    }

    private var isCircular: Bool {
        route.destinationEnglish
            .localizedCaseInsensitiveContains(
                "(CIRCULAR)"
            )
    }

    private var circularDestination: String {
        route.destinationEnglish
            .replacingOccurrences(
                of: "(CIRCULAR)",
                with: "",
                options:
                    .caseInsensitive
            )
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }

    private var operatorRows: [[String]] {
        let operatorIds = Array(
            Set(
                route.operators.flatMap {
                    $0.id.split(separator: "+")
                        .map(String.init)
                }
            )
        )
        .sorted()

        return stride(
            from: 0,
            to: operatorIds.count,
            by: 2
        )
        .map { index in
            Array(
                operatorIds[
                    index..<min(
                        index + 2,
                        operatorIds.count
                    )
                ]
            )
        }
    }

    private var displayedDestination: String {
        isCircular
            ? circularDestination.transitDisplayName
            : route.displayDestination(for: transitLanguage)
    }

    private var favoriteRouteIds: Set<String> {
        Set(
            favoriteRouteIdsValue
                .split(separator: "\n")
                .map(String.init)
        )
    }

    private var isFavorite: Bool {
        favoriteRouteIds.contains(route.id)
    }

    var body: some View {

        VStack(spacing: 0) {

            Picker(
                "Route Section",
                selection: $selectedSection
            ) {

                ForEach(
                    RouteDetailSection.allCases
                ) { section in

                    Text(section.title)
                        .tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            switch selectedSection {
            case .routeDetails:
                routeDetailsContent

            case .stops:
                journeyList
            }
        }
        .navigationTitle(
            "Route \(route.number)"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .background {
            CustomOperatorBackgroundView(
                operatorIds:
                    operatorRows.flatMap { $0 }
            )
        }
        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button {
                    toggleFavorite()
                } label: {
                    Image(
                        systemName:
                            isFavorite
                            ? "bookmark.fill"
                            : "bookmark"
                    )
                }
                .accessibilityLabel(
                    isFavorite
                    ? "Remove from Favorites"
                    : "Add to Favorites"
                )
            }
        }
        .task {
            locationManager.requestLocation()
        }
    }

    private var routeDetailsContent:
        some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {

                CustomRouteDetailedBanner(
                    routeNumber: route.number,
                    origin: route.displayOrigin(for: transitLanguage),
                    destination: displayedDestination
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible())
                    ],
                    spacing: 10
                ) {

                    CustomInfoCardView(
                        title: "Operator"
                    ) {
                        VStack(spacing: 6) {
                            ForEach(
                                operatorRows,
                                id: \.self
                            ) { row in
                                HStack(spacing: 4) {
                                    ForEach(row, id: \.self) {
                                        CustomBadgeView(
                                            operatorId: $0,
                                            isCompact: true,
                                            fontSize: 13
                                        )
                                    }
                                }
                            }
                        }
                    }

                    CustomInfoCardView(
                        title: "Journeys",
                        message:
                            "\(journeys.count)"
                    )

                    CustomInfoCardView(
                        title: "Route Type",
                        message: isCircular
                            ? "Circular"
                            : "Direct"
                    )
                }

                if !journeys.isEmpty {
                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(journeys) { journey in
                            let nearestStop =
                                nearestJourneyStop(
                                    for: journey
                                )

                            CustomCurrentStopETAView(
                                directionName:
                                    directionName(
                                        for: journey
                                    ),
                                stopName: nearestStop?
                                    .stop?
                                    .displayName(for: transitLanguage),
                                etaResult: nearestStop.flatMap {
                                    currentStopETAResults[$0.id]
                                },
                                isLoading: nearestStop.map {
                                    loadingCurrentStopIds
                                        .contains($0.id)
                                } ?? false,
                                isUnavailable: nearestStop.map {
                                    unavailableCurrentStopIds
                                        .contains($0.id)
                                } ?? false,
                                didFail: nearestStop.map {
                                    failedCurrentStopIds
                                        .contains($0.id)
                                } ?? false
                            )
                            .padding(16)
                            .customInfoCardSurface(
                                showsShadow: false
                            )
                            .task(id: nearestStop?.id) {
                                guard let nearestStop else {
                                    return
                                }

                                await loadCurrentStopETA(
                                    journey: journey,
                                    journeyStop: nearestStop
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var journeyList: some View {

        List {

            Section {

                if journeys.isEmpty {

                    Text("No journeys")
                        .foregroundStyle(
                            .secondary
                        )

                } else {

                    ForEach(journeys) { journey in

                        NavigationLink {

                            JourneyStopListView(
                                journey: journey
                            )

                        } label: {

                            JourneySummaryView(
                                journey: journey,
                                isCircular:
                                    isCircular,
                                circularDestination:
                                    circularDestination
                            )
                        }
                    }
                }

            } header: {
                Text("Journeys")
            }
            .listRowBackground(
                Color(uiColor: .systemBackground)
                    .opacity(0.92)
            )
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func orderedStops(
        for journey: JourneyEntity
    ) -> [JourneyStopEntity] {
        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    private func directionName(
        for journey: JourneyEntity
    ) -> String {
        orderedStops(for: journey)
            .last?
            .stop?
            .displayName(for: transitLanguage)
            ?? "Destination unavailable"
    }

    private func nearestJourneyStop(
        for journey: JourneyEntity
    ) -> JourneyStopEntity? {
        guard let userLocation =
            locationManager.location
        else {
            return nil
        }

        return orderedStops(for: journey)
            .filter { $0.stop != nil }
            .min { lhs, rhs in
                distance(from: userLocation, to: lhs) <
                    distance(from: userLocation, to: rhs)
            }
    }

    private func distance(
        from userLocation: CLLocation,
        to journeyStop: JourneyStopEntity
    ) -> CLLocationDistance {
        guard let stop = journeyStop.stop else {
            return .greatestFiniteMagnitude
        }

        return userLocation.distance(
            from: CLLocation(
                latitude: stop.latitude,
                longitude: stop.longitude
            )
        )
    }

    @MainActor
    private func loadCurrentStopETA(
        journey: JourneyEntity,
        journeyStop: JourneyStopEntity
    ) async {
        let stopId = journeyStop.id

        guard
            currentStopETAResults[stopId] == nil,
            !loadingCurrentStopIds.contains(stopId),
            !unavailableCurrentStopIds.contains(stopId),
            !failedCurrentStopIds.contains(stopId)
        else {
            return
        }

        loadingCurrentStopIds.insert(stopId)

        defer {
            loadingCurrentStopIds.remove(stopId)
        }

        do {
            let result = try await RouteETAResolver()
                .resolve(
                    journey: journey,
                    journeyStop: journeyStop,
                    modelContext: modelContext
                )

            if let result {
                currentStopETAResults[stopId] = result
            } else {
                unavailableCurrentStopIds.insert(stopId)
            }

        } catch {
            failedCurrentStopIds.insert(stopId)

            print(
                "Current stop ETA load failed:",
                error
            )
        }
    }

    private func toggleFavorite() {
        var updatedIds = favoriteRouteIds

        if isFavorite {
            updatedIds.remove(route.id)
        } else {
            updatedIds.insert(route.id)
        }

        favoriteRouteIdsValue = updatedIds
            .sorted()
            .joined(separator: "\n")
    }

}

private enum RouteDetailSection:
    String,
    CaseIterable,
    Identifiable {

    case routeDetails
    case stops

    var id: Self { self }

    var title: String {
        switch self {
        case .routeDetails:
            "Route Details"
        case .stops:
            "Journeys"
        }
    }
}
