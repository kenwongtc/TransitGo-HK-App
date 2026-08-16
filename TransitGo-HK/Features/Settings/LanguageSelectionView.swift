//
//  LanguageSelectionView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct LanguageSelectionView: View {
    @AppStorage("appLanguage") private var selectedLanguage = "English"
    let languages = ["English", "繁體中文", "简体中文"]

    var body: some View {
        Form {
            Section(footer: Text("Choose your preferred language for transit information and interface text.")) {
                ForEach(languages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLanguage == language {
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
