//
//  MoreView.swift
//  TransitGo-HK
//
//  Created by Codex on 23/8/2026.
//

import SwiftUI

struct MoreView: View {

    var body: some View {
        NavigationStack {
            List {
                Section("More Operators") {
                    NavigationLink {
                        CrossBoundaryView()
                    } label: {
                        Label(
                            "Cross-Boundary",
                            systemImage: "bus.fill"
                        )
                    }

                    additionalOperatorLink(
                        title: "Tram",
                        systemImage: "tram.fill"
                    )

                    additionalOperatorLink(
                        title: "Peak Tram",
                        systemImage: "cablecar.fill"
                    )

                    additionalOperatorLink(
                        title: "Ferry",
                        systemImage: "ferry.fill"
                    )

                    NavigationLink {
                        AirportBusView()
                    } label: {
                        Label(
                            "Airport Bus",
                            systemImage: "airplane"
                        )
                    }
                }

                Section("Features") {
                    NavigationLink {
                        WidgetFeatureView()
                    } label: {
                        Label(
                            "Widget",
                            systemImage: "square.grid.2x2"
                        )
                    }

                    NavigationLink {
                        RouteFavoritesView()
                    } label: {
                        Label(
                            "Favorites",
                            systemImage: "bookmark"
                        )
                        .symbolVariant(.none)
                    }
                }

                Section("Other") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label(
                            "Settings",
                            systemImage: "gearshape"
                        )
                    }
                }
            }
            .navigationTitle("More")
        }
    }

    private func additionalOperatorLink(
        title: String,
        systemImage: String
    ) -> some View {
        NavigationLink {
            AdditionalOperatorView(
                title: title,
                systemImage: systemImage
            )
        } label: {
            Label(
                LocalizedStringKey(title),
                systemImage: systemImage
            )
        }
    }
}

private struct WidgetFeatureView: View {

    var body: some View {
        CustomCardView(
            imageIcon: "square.grid.2x2",
            title: "Widget",
            subTitle: "This feature will appear here.",
            animated: false
        )
        .navigationTitle("Widget")
    }
}

private struct AdditionalOperatorView: View {

    let title: String
    let systemImage: String

    var body: some View {
        CustomCardView(
            imageIcon: systemImage,
            title: title,
            subTitle: "Services will appear here.",
            animated: false
        )
        .navigationTitle(
            Text(LocalizedStringKey(title))
        )
    }
}

#Preview {
    MoreView()
}
