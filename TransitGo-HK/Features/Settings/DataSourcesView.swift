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

    private var pageText: (
        title: String,
        referenceOnly: String,
        providerDescription: String,
        visitLink: String
    ) {
        switch transitLanguage {
        case .english:
            return (
                "Data Sources",
                "Please use this information for reference only; service schedules may be subject to change due to traffic or operational conditions. We are not responsible for any direct or indirect losses resulting from the use of this service.",
                "Transit data provided in this app is retrieved via the data.gov.hk API. While we strive to ensure the accuracy of the information displayed, we cannot guarantee the reliability, completeness, or timeliness of these data feeds.",
                "Visit data.gov.hk"
            )
        case .traditionalChinese:
            return (
                "資料來源",
                "請僅作參考之用；服務時間表可能因交通或營運情況而有所變動。對於因使用本服務而引致的任何直接或間接損失，我們概不負責。",
                "本應用程式提供的交通資料透過 data.gov.hk API 取得。雖然我們致力確保所顯示資訊的準確性，但無法保證這些資料來源的可靠性、完整性或時效性。",
                "瀏覽 data.gov.hk"
            )
        case .simplifiedChinese:
            return (
                "数据来源",
                "请仅作参考；服务时间表可能因交通或运营情况而有所变动。对于因使用本服务造成的任何直接或间接损失，我们概不负责。",
                "本应用提供的交通数据通过 data.gov.hk API 获取。虽然我们致力于确保所显示信息的准确性，但无法保证这些数据源的可靠性、完整性或时效性。",
                "访问 data.gov.hk"
            )
        }
    }

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
        let pageText = pageText

        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 32
            ) {
                Text(pageText.title)
                    .font(.largeTitle.bold())

                informationCard {
                    Text(pageText.referenceOnly)
                }

                informationCard {
                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {
                        Text(pageText.providerDescription)

                        Divider()

                        Link(
                            pageText.visitLink,
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
