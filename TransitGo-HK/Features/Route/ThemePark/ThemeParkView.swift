import SwiftUI

enum ThemeParkDestination: String, CaseIterable, Identifiable {
    case disneyland
    case oceanPark

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .disneyland: "Disneyland"
        case .oceanPark: "Ocean Park"
        }
    }

    var systemImage: String {
        switch self {
        case .disneyland: "sparkles"
        case .oceanPark: "fish.fill"
        }
    }

    func title(for language: TransitLanguage) -> String {
        switch self {
        case .disneyland: language.localized("Disneyland")
        case .oceanPark: language.localized("Ocean Park")
        }
    }

    func matches(stop: StopEntity) -> Bool {
        let name = stop.nameEnglish.lowercased()

        switch self {
        case .disneyland:
            return name.contains("disneyland")
        case .oceanPark:
            return name.contains("ocean park")
        }
    }
}

struct ThemeParkView: View {
    @Environment(\.transitLanguage)
    private var transitLanguage

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ThemeParkDestination.allCases) { destination in
                    NavigationLink {
                        ThemeParkRouteListView(
                            destination: destination
                        )
                    } label: {
                        CustomInfoCardView(title: "") {
                            VStack(spacing: 8) {
                                Image(systemName: destination.systemImage)
                                    .font(.title2)

                                Text(LocalizedStringKey(destination.titleKey))
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(
            transitLanguage.localized("Theme Park Routes")
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ThemeParkView()
    }
}
