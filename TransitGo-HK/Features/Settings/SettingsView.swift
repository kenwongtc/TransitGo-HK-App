//
//  SettingsView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.transitLanguage)
    private var transitLanguage

    @AppStorage("appLanguage")
    private var selectedLanguage = TransitLanguage.english.rawValue

    @AppStorage(AppAppearance.storageKey)
    private var selectedAppearance = AppAppearance.system.rawValue

    @AppStorage(OperatorSelectionPreference.storageKey)
    private var selectedOperatorIdsValue = ""

    @AppStorage(DefaultAppTab.storageKey)
    private var defaultAppTab = DefaultAppTab.nearby.rawValue

    @AppStorage(MapAppPreference.storageKey)
    private var selectedMapApp =
        MapAppPreference.appleMaps.rawValue

    @AppStorage("favoriteRouteIds")
    private var favoriteRouteIdsValue = ""

    @AppStorage("favoriteStopIds")
    private var favoriteStopIdsValue = ""

    @State
    private var showsCleanFavoritesConfirmation = false

    private var operatorSelectionSummary: String {
        let selectedIds = OperatorSelectionPreference.ids(
            from: selectedOperatorIdsValue
        )

        return selectedIds.isEmpty
            ? "All Operators"
            : selectedIds.sorted().map {
                CustomBadgeView.displayText(
                    for: $0,
                    language: transitLanguage
                )
            }
            .joined(separator: ", ")
    }

    var body: some View {
        List {
                Section(header: Text("Preference")) {
                    NavigationLink(destination: LanguageSelectionView()) {
                        HStack {
                            Label("Language", systemImage: "globe")
                            Spacer()
                            Text(
                                TransitLanguage(
                                    preferenceValue: selectedLanguage
                                )
                                .displayName
                            )
                            .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink(
                        destination: AppearanceSelectionView()
                    ) {
                        HStack {
                            Label(
                                "Appearance",
                                systemImage: "circle.lefthalf.filled"
                            )

                            Spacer()

                            Text(
                                AppAppearance(
                                    rawValue: selectedAppearance
                                )?.displayName
                                    ?? AppAppearance.system.displayName
                            )
                            .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink(destination: OperatorSelectionView()) {
                        HStack {
                            Label("Operators", systemImage: "bus")
                            Spacer()
                            Text(
                                LocalizedStringKey(
                                    operatorSelectionSummary
                                )
                            )
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    NavigationLink(destination: DefaultTabSelectionView()) {
                        HStack {
                            Label(
                                "Default Tab",
                                systemImage: "rectangle.on.rectangle"
                            )

                            Spacer()

                            Text(
                                LocalizedStringKey(
                                    DefaultAppTab(
                                        rawValue: defaultAppTab
                                    )?.displayName
                                        ?? DefaultAppTab.nearby.displayName
                                )
                            )
                            .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink(destination: MapSelectionView()) {
                        HStack {
                            Label(
                                "Map Selection",
                                systemImage: "map"
                            )

                            Spacer()

                            Text(
                                MapAppPreference(
                                    rawValue: selectedMapApp
                                )?.displayName
                                    ?? MapAppPreference.appleMaps.displayName
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("Functions")) {
                    NavigationLink(destination: SmartRouteSearchView()) {
                        Label(
                            "Smart Route Search",
                            systemImage: "point.3.connected.trianglepath.dotted"
                        )
                    }
                }
                
                Section(header: Text("Data Update")) {
                    NavigationLink(destination: DataUpdateView()) {
                        Label("Dataset", systemImage: "cylinder.split.1x2")
                    }

                    Button(role: .destructive) {
                        showsCleanFavoritesConfirmation = true
                    } label: {
                        Label(
                            "Clean Favorite Data",
                            systemImage: "trash"
                        )
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    
                    NavigationLink(destination: DataSourcesView()) {
                        Label("Data Sources", systemImage: "cylinder.split.1x2")
                    }
                    NavigationLink(destination: DisclaimerView()) {
                        Label("Disclaimer", systemImage: "doc.text")
                    }
                }
        }
        .navigationTitle("Settings")
        .tint(.primary)
        .alert(
            "Clean Favorite Data?",
            isPresented: $showsCleanFavoritesConfirmation
        ) {
            Button("No", role: .cancel) {}

            Button("Yes", role: .destructive) {
                favoriteRouteIdsValue = ""
                favoriteStopIdsValue = ""
            }
        } message: {
            Text(
                "This will remove all favorite routes and stops."
            )
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
