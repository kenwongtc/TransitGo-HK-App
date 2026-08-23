//
//  RouteFavoritesView.swift
//  TransitGo-HK
//
//  Created by Ken on 22/8/2026.
//

import SwiftUI

struct RouteFavoritesView: View {

    var body: some View {

        NavigationStack {

            CustomCardView(
                imageIcon: "bookmark",
                title: "No Favorite Routes",
                subTitle: "Routes you save will appear here.",
                animated: false
            )
            .navigationTitle("Favorites")
        }
    }
}

#Preview {
    RouteFavoritesView()
}
