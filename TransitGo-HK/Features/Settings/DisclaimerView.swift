//
//  DisclaimerView.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import SwiftUI

struct DisclaimerView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    private var pageText: (
        title: String,
        thirdPartyData: String,
        referenceOnly: String
    ) {
        switch transitLanguage {
        case .english:
            return (
                "Disclaimer",
                "Information provided in this app, including bus routes, arrival times, and location data, is sourced from third-party APIs. While we strive for accuracy, we cannot guarantee the reliability, completeness, or timeliness of this data.",
                "Please use this information for reference only; service schedules may be subject to change due to traffic or operational conditions. We are not responsible for any direct or indirect losses resulting from the use of this service."
            )
        case .traditionalChinese:
            return (
                "免責聲明",
                "本應用程式所提供的資訊，包括巴士路線、到站時間及位置資料，均取自第三方 API。雖然我們致力確保資料準確，但無法保證其可靠性、完整性或時效性。",
                "請僅作參考之用；服務時間表可能因交通或營運情況而有所變動。對於因使用本服務而引致的任何直接或間接損失，我們概不負責。"
            )
        case .simplifiedChinese:
            return (
                "免责声明",
                "本应用提供的信息，包括公交路线、到站时间和位置数据，均来自第三方 API。虽然我们致力于确保数据准确，但无法保证其可靠性、完整性或时效性。",
                "请仅作参考；服务时间表可能因交通或运营情况而有所变动。对于因使用本服务造成的任何直接或间接损失，我们概不负责。"
            )
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

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    Text(pageText.thirdPartyData)

                    Divider()

                    Text(pageText.referenceOnly)
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
