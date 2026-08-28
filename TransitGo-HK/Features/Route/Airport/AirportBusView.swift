import SwiftUI

struct AirportBusView: View {
    @Environment(\.transitLanguage)
    private var transitLanguage

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AirportRouteCategory.allCases) { category in
                    NavigationLink {
                        AirportRouteAreaView(category: category)
                    } label: {
                        CustomInfoCardView(
                            title: category.title(
                                for: transitLanguage
                            )
                        ) {
                            Text(verbatim: category.displayCode)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Airport Bus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AirportBusView()
    }
}
