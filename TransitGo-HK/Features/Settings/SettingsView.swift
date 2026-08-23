//
//  SettingsView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage")
    private var selectedLanguage = TransitLanguage.english.rawValue

    @AppStorage(OperatorSelectionPreference.storageKey)
    private var selectedOperatorIdsValue = ""

    private var operatorSelectionSummary: String {
        let selectedIds = OperatorSelectionPreference.ids(
            from: selectedOperatorIdsValue
        )

        return selectedIds.isEmpty
            ? "All Operators"
            : selectedIds.sorted().joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
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

                    NavigationLink(destination: OperatorSelectionView()) {
                        HStack {
                            Label("Operators", systemImage: "bus")
                            Spacer()
                            Text(operatorSelectionSummary)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Section(header: Text("Data Update")) {
                    NavigationLink(destination: DataUpdateView()) {
                        Label("Data", systemImage: "cylinder.split.1x2")
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
        }
    }
}


#Preview {
    SettingsView()
}
