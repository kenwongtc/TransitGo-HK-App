import Foundation

enum OperatorSelectionPreference {

    static let storageKey = "selectedOperatorIds"

    static func ids(from value: String) -> Set<String> {
        Set(
            value
                .split(separator: "\n")
                .map(String.init)
        )
    }

    static func value(from ids: Set<String>) -> String {
        ids.sorted().joined(separator: "\n")
    }
}
