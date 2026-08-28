//
//  MoreView.swift
//  TransitGo-HK
//
//  Created by Codex on 23/8/2026.
//

import SwiftUI

struct MoreView: View {
    @State
    private var selectedService: MoreTransportService?

    private let serviceColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("More Operators") {
                    LazyVGrid(
                        columns: serviceColumns,
                        spacing: 12
                    ) {
                        ForEach(MoreTransportService.allCases) { service in
                            Button {
                                selectedService = service
                            } label: {
                                CustomInfoCardView(
                                    title: service.title
                                ) {
                                    Image(systemName: service.systemImage)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(
                    EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 0,
                        trailing: 0
                    )
                )

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
            .navigationDestination(item: $selectedService) { service in
                destination(for: service)
            }
        }
    }

    @ViewBuilder
    private func destination(
        for service: MoreTransportService
    ) -> some View {
        switch service {
        case .airportBus:
            AirportBusView()
        case .crossBoundary:
            CrossBoundaryView()
        case .themePark:
            ThemeParkView()
        case .tram, .peakTram, .ferry:
            AdditionalOperatorView(
                title: service.title,
                systemImage: service.systemImage
            )
        }
    }
}

private enum MoreTransportService: String, CaseIterable, Identifiable {
    case airportBus
    case crossBoundary
    case themePark
    case tram
    case peakTram
    case ferry

    var id: Self { self }

    var title: String {
        switch self {
        case .airportBus: "Airport Bus"
        case .crossBoundary: "Cross-Boundary"
        case .themePark: "Theme Park Routes"
        case .tram: "Tram"
        case .peakTram: "Peak Tram"
        case .ferry: "Ferry"
        }
    }

    var systemImage: String {
        switch self {
        case .airportBus: "airplane"
        case .crossBoundary: "bus.fill"
        case .themePark: "ticket.fill"
        case .tram: "tram.fill"
        case .peakTram: "cablecar.fill"
        case .ferry: "ferry.fill"
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
