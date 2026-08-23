//
//  LanguageSelectionView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct LanguageSelectionView: View {
    @AppStorage("appLanguage")
    private var selectedLanguage = TransitLanguage.english.rawValue

    var body: some View {
        Form {
            Section(footer: Text("Choose your preferred language for transit names.")) {
                ForEach(TransitLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language.rawValue
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLanguage == language.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Language Selection")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSelectionView()
    }
}
