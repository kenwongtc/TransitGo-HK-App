import SwiftUI
import SwiftData

enum AirportRouteCategory: String, CaseIterable, Identifiable {
    case a
    case e
    case night
    case s
    case db

    var id: Self { self }

    var displayCode: String {
        switch self {
        case .a: "A"
        case .e: "E"
        case .night: "NA / N"
        case .s: "S"
        case .db: "DB"
        }
    }

    func matches(routeNumber: String) -> Bool {
        let number = routeNumber.uppercased()

        switch self {
        case .a:
            return number.hasPrefix("A")
        case .e:
            return number.hasPrefix("E")
        case .night:
            return number.hasPrefix("NA") || number.hasPrefix("N")
        case .s:
            return number.hasPrefix("S")
        case .db:
            return number.hasPrefix("DB")
        }
    }

    func title(for language: TransitLanguage) -> String {
        switch (self, language) {
        case (.a, .english): "Direct Airport Routes"
        case (.a, .traditionalChinese): "機場直達路線"
        case (.a, .simplifiedChinese): "机场直达路线"
        case (.e, .english): "External Airport Routes"
        case (.e, .traditionalChinese): "機場對外路線"
        case (.e, .simplifiedChinese): "机场对外路线"
        case (.night, .english): "Overnight Routes"
        case (.night, .traditionalChinese): "通宵路線"
        case (.night, .simplifiedChinese): "通宵路线"
        case (.s, .english): "Airport Shuttle Routes"
        case (.s, .traditionalChinese): "機場穿梭路線"
        case (.s, .simplifiedChinese): "机场穿梭路线"
        case (.db, .english): "Discovery Bay Routes"
        case (.db, .traditionalChinese): "愉景灣路線"
        case (.db, .simplifiedChinese): "愉景湾路线"
        }
    }
}

struct AirportRouteListView: View {
    let category: AirportRouteCategory
    let area: AirportServiceArea?

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    private var airportRoutes: [RouteEntity] {
        routes
            .filter {
                category.matches(routeNumber: $0.number)
                    && AirportRouteGeography.servesAirport($0)
                    && matchesSelectedArea($0)
            }
            .sorted { lhs, rhs in
                let numberComparison = lhs.number
                    .localizedStandardCompare(rhs.number)

                if numberComparison != .orderedSame {
                    return numberComparison == .orderedAscending
                }

                return lhs.displayDestination(for: transitLanguage)
                    .localizedStandardCompare(
                        rhs.displayDestination(for: transitLanguage)
                    ) == .orderedAscending
            }
    }

    var body: some View {
        Group {
            if airportRoutes.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "airplane",
                    description: Text(emptyDescription)
                )
            } else {
                List(airportRoutes) { route in
                    NavigationLink {
                        RouteDetailView(route: route)
                    } label: {
                        RouteRowView(
                            route: route,
                            etaResult: nil,
                            isCompact: true,
                            allowsTwoLineOrigin: true,
                            allowsTwoLineDestination: true,
                            allowsFullNameWrapping: true,
                            usesUniformNameStyle: true
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func matchesSelectedArea(_ route: RouteEntity) -> Bool {
        guard let area else {
            return true
        }

        return AirportRouteGeography.serviceAreas(for: route)
            .contains(area)
    }

    private var navigationTitle: String {
        guard let area else {
            return category.displayCode
        }

        return "\(category.displayCode) · \(area.title(for: transitLanguage))"
    }

    private var emptyTitle: String {
        switch transitLanguage {
        case .english:
            "No \(category.displayCode) Airport Routes"
        case .traditionalChinese:
            "沒有 \(category.displayCode) 機場路線"
        case .simplifiedChinese:
            "没有 \(category.displayCode) 机场路线"
        }
    }

    private var emptyDescription: String {
        switch transitLanguage {
        case .english:
            "Update the dataset and try again."
        case .traditionalChinese:
            "請更新資料集後再試。"
        case .simplifiedChinese:
            "请更新数据集后重试。"
        }
    }
}

enum AirportRouteGeography {
    static func servesAirport(_ route: RouteEntity) -> Bool {
        route.journeys.contains { journey in
            journey.journeyStops.contains { journeyStop in
                isAirportStop(journeyStop.stop)
            }
        }
    }

    static func serviceAreas(
        for route: RouteEntity
    ) -> Set<AirportServiceArea> {
        Set(
            route.journeys.flatMap { journey in
                [journey.originStop, journey.destinationStop]
                    .compactMap { stop in
                        guard !isAirportStop(stop),
                              let regionId = stop?.regionId
                        else {
                            return nil
                        }

                        return AirportServiceArea(rawValue: regionId)
                    }
            }
        )
    }

    private static func isAirportStop(_ stop: StopEntity?) -> Bool {
        guard let stop else {
            return false
        }

        return stop.nameEnglish.localizedCaseInsensitiveContains(
            "airport"
        )
    }
}

#Preview {
    NavigationStack {
        AirportRouteListView(category: .a, area: nil)
    }
    .modelContainer(
        for: [
            RouteEntity.self,
            JourneyEntity.self,
            JourneyStopEntity.self,
            StopEntity.self,
            OperatorEntity.self
        ],
        inMemory: true
    )
}
