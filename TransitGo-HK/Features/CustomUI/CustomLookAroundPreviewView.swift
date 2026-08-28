//
//  CustomLookAroundPreviewView.swift
//  TransitGo-HK
//

import SwiftUI
import MapKit

struct CustomLookAroundPreviewView: View {
    let coordinate: CLLocationCoordinate2D

    @State
    private var scene: MKLookAroundScene?

    @State
    private var isLoading = true

    private var requestID: String {
        "\(coordinate.latitude),\(coordinate.longitude)"
    }

    var body: some View {
        Group {
            if let scene {
                LookAroundPreview(initialScene: scene)
                    .overlay(alignment: .topLeading) {
                        Label(
                            "Look Around",
                            systemImage: "binoculars.fill"
                        )
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(minWidth: 126, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.72))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 8,
                                style: .continuous
                            )
                        )
                        .padding(10)
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
            } else if isLoading {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .fill(.quaternary)
                .overlay {
                    ProgressView()
                }
            }
        }
        .frame(height: scene != nil || isLoading ? 120 : 0)
        .task(id: requestID) {
            isLoading = true

            scene = try? await MKLookAroundSceneRequest(
                coordinate: coordinate
            ).scene

            isLoading = false
        }
    }
}

#Preview {
    CustomLookAroundPreviewView(
        coordinate: CLLocationCoordinate2D(
            latitude: 22.3193,
            longitude: 114.1694
        )
    )
    .padding()
}
