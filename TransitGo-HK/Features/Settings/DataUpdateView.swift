import SwiftUI
import SwiftData

struct DataUpdateView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \OperatorEntity.id)
    private var operators: [OperatorEntity]

    @Query(sort: \RouteEntity.number)
    private var routes: [RouteEntity]

    @State
    private var isUpdating = false

    @State
    private var updateState: UpdateState = .idle

    private let updateStore = ManualDatasetUpdateStore()

    private var sortedOperators: [OperatorEntity] {
        operators.sorted {
            $0.id.localizedStandardCompare($1.id) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section("Operators") {
                ForEach(sortedOperators) { operatorEntity in
                    HStack {
                        CustomBadgeView(
                            operatorId: operatorEntity.id,
                            fontSize: 13
                        )

                        Spacer()

                        Text(
                            "\(routeCount(for: operatorEntity)) routes"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Dataset") {
                LabeledContent("Data Version") {
                    Text(
                        DatasetVersionStore()
                            .installedVersion
                        ?? "Not available"
                    )
                    .foregroundStyle(.secondary)
                }

                LabeledContent("Last Updated") {
                    if let lastUpdatedAt = updateStore.lastUpdatedAt {
                        Text(
                            lastUpdatedAt,
                            format: .dateTime
                                .year()
                                .month()
                                .day()
                                .hour()
                                .minute()
                        )
                        .foregroundStyle(.secondary)
                    } else {
                        Text("Not available")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Manual Update") {
                Button {
                    startManualUpdate()
                } label: {
                    HStack {
                        Label(
                            isUpdating
                            ? "Updating..."
                            : updateState.buttonTitle,
                            systemImage: "arrow.clockwise"
                        )

                        Spacer()

                        if isUpdating {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(
                    isUpdating ||
                    updateStore.remainingUpdatesToday == 0
                )

                if updateStore.remainingUpdatesToday == 0 {
                    Text("Daily update limit reached")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(
                        "\(updateStore.remainingUpdatesToday) updates remaining today"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if case let .failed(message) = updateState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Data Update")
    }

    private func routeCount(
        for operatorEntity: OperatorEntity
    ) -> Int {
        routes.count { route in
            route.operators.contains {
                $0.id.split(separator: "+")
                    .map(String.init)
                    .contains(operatorEntity.id)
            }
        }
    }

    @MainActor
    private func startManualUpdate() {
        guard updateStore.beginManualUpdate() else {
            return
        }

        isUpdating = true
        updateState = .idle

        Task {
            defer {
                isUpdating = false
            }

            do {
                try await DatasetBootstrapper().bootstrap(
                    modelContext: modelContext
                )

                updateStore.recordSuccessfulUpdate()
                updateState = .updated
            } catch {
                updateState = .failed(
                    error.localizedDescription
                )
            }
        }
    }
}

private enum UpdateState {
    case idle
    case updated
    case failed(String)

    var buttonTitle: String {
        switch self {
        case .idle:
            "Update Now"
        case .updated:
            "Updated"
        case .failed:
            "Update Failed"
        }
    }
}

#Preview {
    DataUpdateView()
        .modelContainer(
            for: [OperatorEntity.self, RouteEntity.self],
            inMemory: true
        )
}
