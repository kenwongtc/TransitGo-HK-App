//
//  SettingsView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Preference")) {
                    NavigationLink(destination: LanguageSelectionView()) {
                        Label("Language Selection", systemImage: "globe")
                    }
                }
                
                Section(header: Text("Data Update")) {
                    NavigationLink(destination: LanguageSelectionView()) {
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
