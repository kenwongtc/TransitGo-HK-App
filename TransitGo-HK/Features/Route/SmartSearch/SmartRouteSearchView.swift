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
        switch self {
        case .hki: language.localized("Hong Kong Island")
        case .kln: language.localized("Kowloon")
        case .nt: language.localized("New Territories")
        }
    }
}

private struct SmartSearchDistrict: Identifiable {
    let id: String
    let name: String.LocalizationValue

    func title(for language: TransitLanguage) -> String {
        language.localized(name)
    }

    static let all: [SmartSearchDistrict] = [
        .init(id: "A", name: "Central and Western"),
        .init(id: "B", name: "Wan Chai"),
        .init(id: "C", name: "Eastern"),
        .init(id: "D", name: "Southern"),
        .init(id: "E", name: "Yau Tsim Mong"),
        .init(id: "F", name: "Sham Shui Po"),
        .init(id: "G", name: "Kowloon City"),
        .init(id: "H", name: "Wong Tai Sin"),
        .init(id: "J", name: "Kwun Tong"),
        .init(id: "K", name: "Kwai Tsing"),
        .init(id: "L", name: "Tsuen Wan"),
        .init(id: "M", name: "Tuen Mun"),
        .init(id: "N", name: "Yuen Long"),
        .init(id: "P", name: "North"),
        .init(id: "Q", name: "Tai Po"),
        .init(id: "R", name: "Sha Tin"),
        .init(id: "S", name: "Sai Kung"),
        .init(id: "T", name: "Islands")
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
        transitLanguage.localized("Smart Route Search")
    }

    private var originTitle: String {
        transitLanguage.localized("Origin")
    }

    private var destinationTitle: String {
        transitLanguage.localized("Destination")
    }

    private var showRoutesTitle: String {
        transitLanguage.localized("Show Routes")
    }
}
