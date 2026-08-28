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
        transitLanguage.localized("Suggested Routes")
    }

    private var noRoutesTitle: String {
        transitLanguage.localized("No Direct Routes Found")
    }

    private var noRoutesDescription: String {
        transitLanguage.localized(
            "Try another origin or destination district."
        )
    }
}
