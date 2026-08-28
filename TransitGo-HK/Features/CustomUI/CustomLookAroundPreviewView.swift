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

    @State
    private var showsFullScreenPreview = false

    private var requestID: String {
        "\(coordinate.latitude),\(coordinate.longitude)"
    }

    var body: some View {
        Group {
            if let scene {
                LookAroundPreview(initialScene: scene)
                    .overlay(alignment: .bottomLeading) {
                        Label(
                            "Look Around",
                            systemImage: "binoculars.fill"
                        )
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .padding(10)
                    }
                    .overlay {
                        Button {
                            showsFullScreenPreview = true
                        } label: {
                            Color.clear
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open Look Around")
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
        .fullScreenCover(isPresented: $showsFullScreenPreview) {
            if let scene {
                FullScreenLookAroundView(scene: scene)
            }
        }
        .task(id: requestID) {
            isLoading = true

            scene = try? await MKLookAroundSceneRequest(
                coordinate: coordinate
            ).scene

            isLoading = false
        }
    }
}

private struct FullScreenLookAroundView: View {
    let scene: MKLookAroundScene

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            LookAroundPreview(initialScene: scene)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Look Around")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
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
