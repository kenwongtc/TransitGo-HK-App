import SwiftUI
import SwiftData

enum AirportServiceArea: String, CaseIterable, Identifiable {
    case hki
    case kln
    case nt

    var id: Self { self }

    var displayCode: String {
        rawValue.uppercased()
    }

    func title(for language: TransitLanguage) -> String {
        switch (self, language) {
        case (.hki, .english): "Hong Kong Island"
        case (.hki, .traditionalChinese): "香港島"
        case (.hki, .simplifiedChinese): "香港岛"
        case (.kln, .english): "Kowloon"
        case (.kln, .traditionalChinese): "九龍"
        case (.kln, .simplifiedChinese): "九龙"
        case (.nt, .english): "New Territories"
        case (.nt, .traditionalChinese): "新界"
        case (.nt, .simplifiedChinese): "新界"
        }
    }
}

struct AirportRouteAreaView: View {
    let category: AirportRouteCategory

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var availableAreas: [AirportServiceArea] {
        AirportServiceArea.allCases.filter { area in
            matchingRoutes.contains { route in
                AirportRouteGeography.serviceAreas(for: route)
                    .contains(area)
            }
        }
    }

    private var matchingRoutes: [RouteEntity] {
        routes.filter {
            category.matches(routeNumber: $0.number)
                && AirportRouteGeography.servesAirport($0)
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink {
                    AirportRouteListView(
                        category: category,
                        area: nil
                    )
                } label: {
                    areaCard(
                        message: allRoutesTitle
                    )
                }
                .buttonStyle(.plain)

                ForEach(availableAreas) { area in
                    NavigationLink {
                        AirportRouteListView(
                            category: category,
                            area: area
                        )
                    } label: {
                        areaCard(
                            message: area.title(for: transitLanguage)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(
            category.navigationTitle(
                for: transitLanguage
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private func areaCard(
        message: String
    ) -> some View {
        CustomInfoCardView(title: departureAreaTitle) {
            Text(verbatim: message)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
        }
    }

    private var allRoutesTitle: String {
        switch transitLanguage {
        case .english: "All Routes"
        case .traditionalChinese: "所有路線"
        case .simplifiedChinese: "所有路线"
        }
    }

    private var departureAreaTitle: String {
        switch transitLanguage {
        case .english: "Departing From"
        case .traditionalChinese: "出發地區"
        case .simplifiedChinese: "出发地区"
        }
    }
}

#Preview {
    NavigationStack {
        AirportRouteAreaView(category: .a)
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
