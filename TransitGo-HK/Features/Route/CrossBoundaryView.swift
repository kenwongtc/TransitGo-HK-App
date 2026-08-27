import SwiftUI

struct CrossBoundaryView: View {

    var body: some View {
        CustomCardView(
            imageIcon: "bus.fill",
            title: "Cross-Boundary",
            subTitle: "Cross-boundary transit services will appear here.",
            animated: false
        )
        .navigationTitle("Cross-Boundary")
    }
}

#Preview {
    NavigationStack {
        CrossBoundaryView()
    }
}
