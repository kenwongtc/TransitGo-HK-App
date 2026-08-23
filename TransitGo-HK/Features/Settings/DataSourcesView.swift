//
//  DataSourcesView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct DataSourcesView: View {

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 32
            ) {
                Text(
                    String(
                        localized: "settings.dataSources.title"
                    )
                )
                    .font(.largeTitle.bold())

                informationCard {
                    Text(
                        String(
                            localized:
                                "settings.dataSources.referenceOnly"
                        )
                    )
                }

                informationCard {
                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {
                        Text(
                            String(
                                localized:
                                    "settings.dataSources.providerDescription"
                            )
                        )

                        Divider()

                        Link(
                            String(
                                localized:
                                    "settings.dataSources.visitLink"
                            ),
                            destination: URL(
                                string: "https://data.gov.hk"
                            )!
                        )
                    }
                }
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

    private func informationCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(20)
            .customInfoCardSurface(
                showsShadow: false
            )
    }
}
