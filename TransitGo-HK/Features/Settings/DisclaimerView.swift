//
//  DisclaimerView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct DisclaimerView: View {

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 32
            ) {
                Text(
                    String(
                        localized: "settings.disclaimer.title"
                    )
                )
                    .font(.largeTitle.bold())

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    Text(
                        String(
                            localized:
                                "settings.disclaimer.thirdPartyData"
                        )
                    )

                    Divider()

                    Text(
                        String(
                            localized:
                                "settings.disclaimer.referenceOnly"
                        )
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(20)
                .customInfoCardSurface(
                    showsShadow: false
                )
            }
            .font(.body)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(
            Color(uiColor: .systemGroupedBackground)
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
