import SwiftUI
import SwiftData

struct AirportBusView: View {
    @Environment(\.transitLanguage)
    private var transitLanguage

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    private var airportRoutes: [RouteEntity] {
        routes
            .filter(servesAirport)
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
                List {
                    Section {
                        ForEach(airportRoutes) { route in
                            NavigationLink {
                                RouteDetailView(route: route)
                            } label: {
                                RouteRowView(
                                    route: route,
                                    etaResult: nil,
                                    isCompact: true,
                                    allowsTwoLineOrigin: true,
                                    allowsTwoLineDestination: true,
                                    usesUniformNameStyle: true
                                )
                            }
                        }
                    } header: {
                        Text(verbatim: routeSectionTitle)
                    } footer: {
                        Text(verbatim: routeSectionFooter)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Airport Bus")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func servesAirport(_ route: RouteEntity) -> Bool {
        route.journeys.contains { journey in
            journey.journeyStops.contains { journeyStop in
                guard let stopName = journeyStop.stop?.nameEnglish else {
                    return false
                }

                return stopName.localizedCaseInsensitiveContains(
                    "airport"
                )
            }
        }
    }

    private var routeSectionTitle: String {
        switch transitLanguage {
        case .english:
            "Routes serving the airport"
        case .traditionalChinese:
            "途經機場的路線"
        case .simplifiedChinese:
            "途经机场的路线"
        }
    }

    private var routeSectionFooter: String {
        switch transitLanguage {
        case .english:
            "Routes are identified from stops in the TransitGo dataset."
        case .traditionalChinese:
            "路線按 TransitGo 資料集內的機場車站識別。"
        case .simplifiedChinese:
            "路线按 TransitGo 数据集内的机场车站识别。"
        }
    }

    private var emptyTitle: String {
        switch transitLanguage {
        case .english:
            "No Airport Routes"
        case .traditionalChinese:
            "沒有機場路線"
        case .simplifiedChinese:
            "没有机场路线"
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

#Preview {
    NavigationStack {
        AirportBusView()
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
