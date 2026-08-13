import SwiftUI

struct RouteDetailView: View {

    let route: RouteEntity

    private var journeys: [JourneyEntity] {
        route.journeys.sorted {
            $0.direction < $1.direction
        }
    }

    private var isCircular: Bool {
        route.destinationEnglish
            .localizedCaseInsensitiveContains("(CIRCULAR)")
    }

    private var circularDestination: String {
        route.destinationEnglish
            .replacingOccurrences(
                of: "(CIRCULAR)",
                with: "",
                options: .caseInsensitive
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    var body: some View {
        List {

            Section("Route") {

                LabeledContent(
                    "Number",
                    value: route.number
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(route.originEnglish)
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(route.destinationEnglish)
                }
            }

            Section("Operators") {
                ForEach(route.operators) { operatorEntity in
                    Text(operatorEntity.nameEnglish)
                }
            }

            Section("Journeys") {

                if journeys.isEmpty {

                    Text("No journeys")
                        .foregroundStyle(.secondary)

                } else {

                    ForEach(journeys) { journey in
                        NavigationLink {
                            JourneyStopListView(
                                journey: journey
                            )
                        } label: {
                            JourneySummaryView(
                                journey: journey,
                                isCircular: isCircular,
                                circularDestination: circularDestination
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(route.number)
        .navigationBarTitleDisplayMode(.large)
    }
}
