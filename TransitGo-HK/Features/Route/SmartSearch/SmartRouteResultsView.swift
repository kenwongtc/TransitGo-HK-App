import SwiftUI
import SwiftData

struct SmartRouteResultsView: View {
    let originDistrictId: String
    let destinationDistrictId: String

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    private var matchingRoutes: [RouteEntity] {
        routes.filter { route in
            route.journeys.contains { journey in
                journey.originStop?.districtId == originDistrictId
                    && journey.destinationStop?.districtId == destinationDistrictId
            }
        }
    }

    var body: some View {
        Group {
            if matchingRoutes.isEmpty {
                ContentUnavailableView(
                    noRoutesTitle,
                    systemImage: "bus",
                    description: Text(noRoutesDescription)
                )
            } else {
                List(matchingRoutes) { route in
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
                .listStyle(.plain)
            }
        }
        .navigationTitle(resultsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resultsTitle: String {
        switch transitLanguage {
        case .english: "Suggested Routes"
        case .traditionalChinese: "建議路線"
        case .simplifiedChinese: "建议路线"
        }
    }

    private var noRoutesTitle: String {
        switch transitLanguage {
        case .english: "No Direct Routes Found"
        case .traditionalChinese: "找不到直達路線"
        case .simplifiedChinese: "找不到直达路线"
        }
    }

    private var noRoutesDescription: String {
        switch transitLanguage {
        case .english:
            "Try another origin or destination district."
        case .traditionalChinese:
            "請嘗試其他起點或目的地地區。"
        case .simplifiedChinese:
            "请尝试其他起点或目的地区域。"
        }
    }
}
