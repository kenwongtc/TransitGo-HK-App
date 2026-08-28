import SwiftUI

private enum SmartSearchRegion: String, CaseIterable, Identifiable {
    case hki
    case kln
    case nt

    var id: Self { self }

    var districtCodes: [String] {
        switch self {
        case .hki: ["A", "B", "C", "D"]
        case .kln: ["E", "F", "G", "H", "J"]
        case .nt: ["K", "L", "M", "N", "P", "Q", "R", "S", "T"]
        }
    }

    func title(for language: TransitLanguage) -> String {
        switch (self, language) {
        case (.hki, .english): "Hong Kong Island"
        case (.hki, .traditionalChinese): "香港島"
        case (.hki, .simplifiedChinese): "香港岛"
        case (.kln, .english): "Kowloon"
        case (.kln, .traditionalChinese): "九龍"
        case (.kln, .simplifiedChinese): "九龙"
        case (.nt, .english): "New Territories"
        case (.nt, .traditionalChinese): "新界"
        case (.nt, .simplifiedChinese): "新界"
        }
    }
}

private struct SmartSearchDistrict: Identifiable {
    let id: String
    let english: String
    let traditional: String
    let simplified: String

    func title(for language: TransitLanguage) -> String {
        switch language {
        case .english: english
        case .traditionalChinese: traditional
        case .simplifiedChinese: simplified
        }
    }

    static let all: [SmartSearchDistrict] = [
        .init(id: "A", english: "Central and Western", traditional: "中西區", simplified: "中西区"),
        .init(id: "B", english: "Wan Chai", traditional: "灣仔區", simplified: "湾仔区"),
        .init(id: "C", english: "Eastern", traditional: "東區", simplified: "东区"),
        .init(id: "D", english: "Southern", traditional: "南區", simplified: "南区"),
        .init(id: "E", english: "Yau Tsim Mong", traditional: "油尖旺區", simplified: "油尖旺区"),
        .init(id: "F", english: "Sham Shui Po", traditional: "深水埗區", simplified: "深水埗区"),
        .init(id: "G", english: "Kowloon City", traditional: "九龍城區", simplified: "九龙城区"),
        .init(id: "H", english: "Wong Tai Sin", traditional: "黃大仙區", simplified: "黄大仙区"),
        .init(id: "J", english: "Kwun Tong", traditional: "觀塘區", simplified: "观塘区"),
        .init(id: "K", english: "Kwai Tsing", traditional: "葵青區", simplified: "葵青区"),
        .init(id: "L", english: "Tsuen Wan", traditional: "荃灣區", simplified: "荃湾区"),
        .init(id: "M", english: "Tuen Mun", traditional: "屯門區", simplified: "屯门区"),
        .init(id: "N", english: "Yuen Long", traditional: "元朗區", simplified: "元朗区"),
        .init(id: "P", english: "North", traditional: "北區", simplified: "北区"),
        .init(id: "Q", english: "Tai Po", traditional: "大埔區", simplified: "大埔区"),
        .init(id: "R", english: "Sha Tin", traditional: "沙田區", simplified: "沙田区"),
        .init(id: "S", english: "Sai Kung", traditional: "西貢區", simplified: "西贡区"),
        .init(id: "T", english: "Islands", traditional: "離島區", simplified: "离岛区")
    ]

    static func district(id: String?) -> SmartSearchDistrict? {
        all.first { $0.id == id }
    }
}

struct SmartRouteSearchView: View {
    @Environment(\.transitLanguage)
    private var transitLanguage

    @State private var originRegion: SmartSearchRegion?
    @State private var originDistrictId: String?
    @State private var destinationRegion: SmartSearchRegion?
    @State private var destinationDistrictId: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                selectionSection(
                    title: originTitle,
                    region: $originRegion,
                    districtId: $originDistrictId
                )

                selectionSection(
                    title: destinationTitle,
                    region: $destinationRegion,
                    districtId: $destinationDistrictId
                )

                if let originDistrictId,
                   let destinationDistrictId {
                    NavigationLink {
                        SmartRouteResultsView(
                            originDistrictId: originDistrictId,
                            destinationDistrictId: destinationDistrictId
                        )
                    } label: {
                        Label(showRoutesTitle, systemImage: "bus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.tint, in: .rect(cornerRadius: 18))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(smartSearchTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectionSection(
        title: String,
        region: Binding<SmartSearchRegion?>,
        districtId: Binding<String?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(SmartSearchRegion.allCases) { option in
                    Button {
                        region.wrappedValue = option
                        districtId.wrappedValue = nil
                    } label: {
                        Text(option.title(for: transitLanguage))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                region.wrappedValue == option
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.white,
                                in: .rect(cornerRadius: 14)
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedRegion = region.wrappedValue {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 145))],
                    spacing: 10
                ) {
                    ForEach(selectedRegion.districtCodes, id: \.self) { code in
                        if let district = SmartSearchDistrict.district(id: code) {
                            Button {
                                districtId.wrappedValue = code
                            } label: {
                                Text(district.title(for: transitLanguage))
                                    .font(.body.weight(.medium))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        districtId.wrappedValue == code
                                            ? Color.accentColor.opacity(0.18)
                                            : Color.white,
                                        in: .rect(cornerRadius: 14)
                                    )
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var smartSearchTitle: String {
        switch transitLanguage {
        case .english: "Smart Route Search"
        case .traditionalChinese: "智能路線搜尋"
        case .simplifiedChinese: "智能路线搜索"
        }
    }

    private var originTitle: String {
        switch transitLanguage {
        case .english: "Origin"
        case .traditionalChinese: "起點"
        case .simplifiedChinese: "起点"
        }
    }

    private var destinationTitle: String {
        switch transitLanguage {
        case .english: "Destination"
        case .traditionalChinese: "目的地"
        case .simplifiedChinese: "目的地"
        }
    }

    private var showRoutesTitle: String {
        switch transitLanguage {
        case .english: "Show Routes"
        case .traditionalChinese: "顯示路線"
        case .simplifiedChinese: "显示路线"
        }
    }
}
