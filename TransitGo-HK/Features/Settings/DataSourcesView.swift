//
//  DataSourcesView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct DataSourcesView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    private var fareSourceText: (
        title: String,
        description: String,
        updated: String,
        link: String
    ) {
        switch transitLanguage {
        case .english:
            return (
                "Fare Data",
                "Full, sectional, and boarding fares are provided by the Hong Kong Transport Department through DATA.GOV.HK.",
                "Fare data updated",
                "View Transport Department fare data"
            )
        case .traditionalChinese:
            return (
                "車費資料",
                "全程、分段及上車收費資料由香港運輸署透過 DATA.GOV.HK 提供。",
                "車費資料更新日期",
                "查看運輸署車費資料"
            )
        case .simplifiedChinese:
            return (
                "车费资料",
                "全程、分段及上车收费资料由香港运输署通过 DATA.GOV.HK 提供。",
                "车费资料更新日期",
                "查看运输署车费资料"
            )
        }
    }

    private var fareDataUpdatedDate: String? {
        DatasetVersionStore().fareDataUpdatedAt.map {
            String($0.prefix(10))
        }
    }

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

                informationCard {
                    let text = fareSourceText

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {
                        Label(
                            text.title,
                            systemImage: "dollarsign.circle"
                        )
                        .font(.headline)

                        Text(text.description)

                        if let fareDataUpdatedDate {
                            Text(
                                "\(text.updated): " +
                                    fareDataUpdatedDate
                            )
                            .foregroundStyle(.secondary)
                        }

                        Link(
                            text.link,
                            destination: URL(
                                string: "https://data.gov.hk/en-data/dataset/hk-td-tis_14-routes-fares-xml"
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
