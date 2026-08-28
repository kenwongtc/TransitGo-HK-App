//
//  JourneyStopListView.swift
//  TransitGo-HK
//
//  Created by Ken on 11/8/2026.
//d

import SwiftUI
import SwiftData
import CoreLocation

struct JourneyStopListView: View {

    let journey: JourneyEntity

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Environment(\.locale)
    private var locale

    private func stopCode(for journeyStop: JourneyStopEntity) -> String? {
        journeyStop.publicStopCode
    }

    private func boardingFareText(
        for journeyStop: JourneyStopEntity
    ) -> String? {
        guard journeyStop.stopPickDrop != "1" else {
            return nil
        }

        guard let fare = journey.boardingFareCents(
            at: journeyStop.sequence
        ), fare > 0 else {
            return nil
        }

        return String(
            format: "$%.2f",
            Double(fare) / 100
        )
    }

    @State
    private var etaResults:
        [String: RouteETAResult] = [:]

    @State
    private var loadingStopIds:
        Set<String> = []

    @State
    private var unavailableStopIds:
        Set<String> = []

    @State
    private var failedStopIds:
        Set<String> = []

    @Environment(AppLocationManager.self)
    private var locationManager

    private var orderedStops:
        [JourneyStopEntity] {

        journey.journeyStops.sorted {
            $0.sequence < $1.sequence
        }
    }

    private var operatorIds: [String] {
        Array(
            Set(
                journey.route?.operators.flatMap {
                    $0.id.split(separator: "+")
                        .map(String.init)
                } ?? []
            )
        )
        .sorted()
    }

    private var nearestJourneyStop:
        JourneyStopEntity? {

        guard let userLocation =
            locationManager.location
        else {
            return nil
        }

        return orderedStops
            .filter {
                $0.stop != nil && $0.stopPickDrop != "1"
            }
            .min { lhs, rhs in
                distance(from: userLocation, to: lhs) <
                    distance(from: userLocation, to: rhs)
            }
    }

    private var isMoreThanOneKilometerAway: Bool {
        guard
            let userLocation = locationManager.location,
            let nearestJourneyStop
        else {
            return false
        }

        return distance(
            from: userLocation,
            to: nearestJourneyStop
        ) > 1_000
    }

    private var dataSourceFooterText: String {
        switch transitLanguage {
        case .english:
            "Data provided by data.gov.hk"
        case .traditionalChinese:
            "資料由 data.gov.hk 提供"
        case .simplifiedChinese:
            "数据由 data.gov.hk 提供"
        }
    }

    private var navigationTitleText: String {
        guard let routeNumber = journey.route?.number else {
            switch transitLanguage {
            case .english:
                return "Journey"
            case .traditionalChinese:
                return "行程"
            case .simplifiedChinese:
                return "行程"
            }
        }

        switch transitLanguage {
        case .english:
            return "Route \(routeNumber)"
        case .traditionalChinese:
            return "路線\(routeNumber)"
        case .simplifiedChinese:
            return "路线\(routeNumber)"
        }
    }

    var body: some View {

        ScrollViewReader { scrollProxy in
            List {

            // MARK: - Journey Summary

            Section {
                CustomRouteBannerView(
                    routeNumber: journey.route?.number,
                    origin: orderedStops.first?
                        .stop?
                        .displayName(for: transitLanguage)
                        ?? String(
                            localized: "Origin unavailable",
                            locale: locale
                        ),
                    destination: orderedStops.last?
                        .stop?
                        .displayName(for: transitLanguage)
                        ?? String(
                            localized: "Destination unavailable",
                            locale: locale
                        )
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(
                EdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
            )

            // MARK: - Map

            Section {

                NavigationLink {

                    JourneyMapView(
                        journey: journey
                    )

                } label: {

                    Label(
                        "View Journey Map",
                        systemImage: "map"
                    )
                }
            }
            .listRowBackground(
                Color(uiColor: .systemBackground)
                    .opacity(0.92)
            )

            // MARK: - Nearest Stop

            if isMoreThanOneKilometerAway {
                Section {
                    Label(
                        "You are over 1 km away from this route",
                        systemImage: "location.slash.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.orange)
                }
                .listRowBackground(
                    Color(uiColor: .systemBackground)
                        .opacity(0.92)
                )
            }

            Section {
                Button {
                    guard let nearestJourneyStop else {
                        return
                    }

                    withAnimation {
                        scrollProxy.scrollTo(
                            nearestJourneyStop.id,
                            anchor: .center
                        )
                    }
                } label: {
                    CustomCurrentStopETAView(
                        stopName: nearestJourneyStop?
                            .stop?
                            .displayName(for: transitLanguage),
                        stopCode: nearestJourneyStop.flatMap(stopCode),
                        showsStopName: false,
                        etaResult: nearestJourneyStop.flatMap {
                            etaResults[$0.id]
                        },
                        isLoading: nearestJourneyStop.map {
                            loadingStopIds.contains($0.id)
                        } ?? false,
                        isUnavailable: nearestJourneyStop.map {
                            unavailableStopIds.contains($0.id)
                        } ?? false,
                        didFail: nearestJourneyStop.map {
                            failedStopIds.contains($0.id)
                        } ?? false
                    )
                }
                .buttonStyle(.plain)
                .disabled(nearestJourneyStop == nil)
                .task(id: nearestJourneyStop?.id) {
                    guard let nearestJourneyStop else {
                        return
                    }

                    await loadETA(
                        for: nearestJourneyStop
                    )
                }
            } header: {
                if let stopName = nearestJourneyStop?
                    .stop?
                    .displayName(for: transitLanguage) {
                    HStack(spacing: 0) {
                        Text("Nearest Stop")
                        Text(
                            verbatim: transitLanguage == .english
                                ? ": "
                                : "："
                        )
                        Text(verbatim: stopName)
                        if let nearestJourneyStop,
                           let code = stopCode(for: nearestJourneyStop) {
                            Text(verbatim: " (\(code))")
                        }
                    }
                } else {
                    Text("Nearest Stop")
                }
            }
            .listRowBackground(
                Color(uiColor: .systemBackground)
                    .opacity(0.92)
            )

            // MARK: - Stops

            Section {

                ForEach(
                    Array(
                        orderedStops.enumerated()
                    ),
                    id: \.element.id
                ) { index, journeyStop in

                    if let stop =
                        journeyStop.stop {

                        NavigationLink {

                            StopDetailView(
                                stop: stop,
                                journey: journey,
                                journeyStop:
                                    journeyStop
                            )

                        } label: {

                            StopRowView(
                                journeyStop:
                                    journeyStop,
                                isFirst:
                                    index == 0,
                                isLast:
                                    index == orderedStops.count - 1,
                                stop:
                                    stop,
                                stopCode: stopCode(for: journeyStop),
                                boardingFareText:
                                    boardingFareText(
                                        for: journeyStop
                                    ),
                                operatorIds:
                                    operatorIds,
                                isHighlighted:
                                    journeyStop.id ==
                                        nearestJourneyStop?.id,
                                etaResult:
                                    etaResults[
                                        journeyStop.id
                                    ],
                                isLoadingETA:
                                    loadingStopIds
                                        .contains(
                                            journeyStop.id
                                        ),
                                isETAUnavailable:
                                    unavailableStopIds
                                        .contains(
                                            journeyStop.id
                                        ),
                                didETAFail:
                                    failedStopIds
                                        .contains(
                                            journeyStop.id
                                        )
                            )
                            .task {
                                if journeyStop.stopPickDrop != "1" {
                                    await loadETA(
                                        for: journeyStop
                                    )
                                }
                            }
                        }
                        .id(journeyStop.id)
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: 16,
                                bottom: 0,
                                trailing: 16
                            )
                        )
                        .listRowSeparator(.hidden)

                    } else {

                        HStack(
                            alignment: .top,
                            spacing: 12
                        ) {

                            CustomStopLineView(
                                sequence:
                                    journeyStop.sequence,
                                isFirst:
                                    index == 0,
                                isLast:
                                    index == orderedStops.count - 1,
                                operatorIds:
                                    operatorIds,
                                isHighlighted:
                                    journeyStop.id ==
                                        nearestJourneyStop?.id
                            )

                            Text(
                                "Stop unavailable"
                            )
                            .foregroundStyle(
                                .secondary
                            )
                            .padding(
                                .vertical,
                                14
                            )
                        }
                        .id(journeyStop.id)
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: 16,
                                bottom: 0,
                                trailing: 16
                            )
                        )
                        .listRowSeparator(.hidden)
                    }
                }

            } header: {

                Text(
                    "Stops: \(orderedStops.count)"
                )
            }
            .listRowBackground(
                Color(uiColor: .systemBackground)
                    .opacity(0.92)
            )
        }
        .scrollContentBackground(.hidden)
        .background {
            CustomOperatorBackgroundView(
                operatorIds: operatorIds
            )
        }
        .contentMargins(
            .top,
            0,
            for: .scrollContent
        )
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {
            locationManager.requestLocation()
        }
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {
            Text(dataSourceFooterText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.bar)
        }
        }
    }

    private func distance(
        from userLocation: CLLocation,
        to journeyStop: JourneyStopEntity
    ) -> CLLocationDistance {
        guard let stop = journeyStop.stop else {
            return .greatestFiniteMagnitude
        }

        return userLocation.distance(
            from: CLLocation(
                latitude: stop.latitude,
                longitude: stop.longitude
            )
        )
    }

    // MARK: - Stop ETA

    @MainActor
    private func loadETA(
        for journeyStop:
            JourneyStopEntity
    ) async {

        let stopId =
            journeyStop.id

        guard
            etaResults[stopId] == nil,
            !unavailableStopIds
                .contains(stopId),
            !failedStopIds
                .contains(stopId),
            !loadingStopIds
                .contains(stopId)
        else {
            return
        }

        loadingStopIds.insert(
            stopId
        )

        defer {

            loadingStopIds.remove(
                stopId
            )
        }

        do {

            let result =
                try await RouteETAResolver()
                    .resolve(
                        journey: journey,
                        journeyStop:
                            journeyStop,
                        modelContext:
                            modelContext
                    )

            if let result {

                etaResults[stopId] =
                    result

            } else {

                unavailableStopIds
                    .insert(stopId)
            }

        } catch {

            failedStopIds.insert(
                stopId
            )
        }
    }

}


// MARK: - Stop Row

private struct StopRowView: View {

    @Environment(\.transitLanguage)
    private var transitLanguage

    @Environment(\.locale)
    private var locale

    let journeyStop:
        JourneyStopEntity

    let isFirst: Bool

    let isLast: Bool

    let stop:
        StopEntity

    let stopCode: String?

    let boardingFareText: String?

    let operatorIds: [String]

    let isHighlighted: Bool

    let etaResult:
        RouteETAResult?

    let isLoadingETA: Bool

    let isETAUnavailable: Bool

    let didETAFail: Bool

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            CustomStopLineView(
                sequence:
                    journeyStop.sequence,
                isFirst: isFirst,
                isLast: isLast,
                operatorIds: operatorIds,
                isHighlighted: isHighlighted
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(stop.displayName(for: transitLanguage))
                        .font(isHighlighted ? .title3 : .body)
                        .fontWeight(isHighlighted ? .bold : .regular)

                    if let stopCode {
                        Text(verbatim: "(\(stopCode))")
                            .font(isHighlighted ? .title3 : .body)
                            .fontWeight(isHighlighted ? .bold : .regular)
                            .foregroundStyle(.secondary)
                    }
                }

                if let boardingFareText {
                    Text(boardingFareText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                if let stopRoleText {
                    Text(stopRoleText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            journeyStop.stopPickDrop == "1"
                                ? Color.secondary
                                : Color.accentColor
                        )
                }
            }
            .padding(
                .vertical,
                14
            )

            Spacer()

            // MARK: ETA

            Group {
                if journeyStop.stopPickDrop == "1" {
                    EmptyView()
                } else if isLoadingETA {
                    ProgressView()
                        .controlSize(.small)

                } else if isETAUnavailable {

                    Text("Unavailable")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                } else if didETAFail {

                    Text("Error")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                } else {

                    TimelineView(
                        .periodic(
                            from: .now,
                            by: 1
                        )
                    ) { context in

                        if let nextArrival =
                            nextArrival(
                                at: context.date
                            ) {

                            Text(
                                etaText(
                                    for: nextArrival,
                                    relativeTo:
                                        context.date
                                )
                            )
                            .font(.subheadline)
                            .fontWeight(
                                isHighlighted
                                ? .bold
                                : .regular
                            )
                            .monospacedDigit()

                        } else if etaResult != nil {

                            Text("No ETA")
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                        }
                    }
                }
            }
            .frame(
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }

    private var stopRoleText: String? {
        switch journeyStop.stopPickDrop {
        case "1":
            switch transitLanguage {
            case .english: "Alighting only"
            case .traditionalChinese: "只供落客"
            case .simplifiedChinese: "只供下客"
            }
        case "2":
            switch transitLanguage {
            case .english: "Boarding only"
            case .traditionalChinese: "只供上客"
            case .simplifiedChinese: "只供上客"
            }
        default:
            nil
        }
    }

    // MARK: - Next Arrival

    private func nextArrival(
        at date: Date
    ) -> Date? {

        etaResult?
            .etaRecords
            .compactMap {
                $0.estimatedArrival
            }
            .filter {
                $0 >= date
            }
            .min()
    }

    // MARK: - ETA Text

    private func etaText(
        for arrival: Date,
        relativeTo date: Date
    ) -> String {

        let seconds =
            max(
                0,
                Int(
                    arrival
                        .timeIntervalSince(
                            date
                        )
                )
            )

        let minutes =
            seconds / 60

        if minutes == 0 {
            switch transitLanguage {
            case .english:
                return "Due"
            case .traditionalChinese:
                return "即將到站"
            case .simplifiedChinese:
                return "即将到站"
            }
        }

        switch transitLanguage {
        case .english:
            return "\(minutes) min"
        case .traditionalChinese:
            return "\(minutes) 分鐘"
        case .simplifiedChinese:
            return "\(minutes) 分钟"
        }
    }
}
