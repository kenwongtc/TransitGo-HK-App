import SwiftUI

struct AppearanceSelectionView: View {
    @Environment(\.dismiss)
    private var dismiss

    @AppStorage(AppAppearance.storageKey)
    private var selectedAppearance = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Section(
                footer: Text(
                    "Choose how TransitGo appears on this device."
                )
            ) {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        selectedAppearance = appearance.rawValue
                        dismiss()
                    } label: {
                        HStack {
                            Text(appearance.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedAppearance == appearance.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSelectionView()
    }
}
