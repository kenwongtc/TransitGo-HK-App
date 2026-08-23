import SwiftUI
import SwiftData

struct OperatorSelectionView: View {

    @Query(sort: \OperatorEntity.id)
    private var operators: [OperatorEntity]

    @AppStorage(OperatorSelectionPreference.storageKey)
    private var selectedOperatorIdsValue = ""

    private var selectedOperatorIds: Set<String> {
        OperatorSelectionPreference.ids(
            from: selectedOperatorIdsValue
        )
    }

    var body: some View {
        List {
            Section {
                Button {
                    selectedOperatorIdsValue = ""
                } label: {
                    selectionLabel(
                        title: "All Operators",
                        isSelected: selectedOperatorIds.isEmpty
                    )
                }
            }

            Section("Operators") {
                ForEach(operators) { operatorEntity in
                    Button {
                        toggle(operatorEntity.id)
                    } label: {
                        selectionLabel(
                            title: operatorEntity.id,
                            isSelected:
                                selectedOperatorIds
                                .contains(operatorEntity.id)
                        )
                    }
                }
            }
        }
        .navigationTitle("Operators")
    }

    private func selectionLabel(
        title: String,
        isSelected: Bool
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            }
        }
    }

    private func toggle(_ operatorId: String) {
        var selection = selectedOperatorIds

        if selection.contains(operatorId) {
            selection.remove(operatorId)
        } else {
            selection.insert(operatorId)
        }

        selectedOperatorIdsValue =
            OperatorSelectionPreference.value(
                from: selection
            )
    }
}

#Preview {
    NavigationStack {
        OperatorSelectionView()
    }
    .modelContainer(
        for: OperatorEntity.self,
        inMemory: true
    )
}
