//
//  TransitGo_HKApp.swift
//  TransitGo-HK
//
//  Created by Ken on 10/8/2026.
//

import SwiftUI
import SwiftData

@main
struct TransitGo_HKApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [
                OperatorEntity.self,
                 RouteEntity.self,
                 StopEntity.self,
                 JourneyEntity.self,
                 JourneyStopEntity.self,
                 ScheduleEntity.self,
                 OperatorStopReferenceEntity.self
            ]
        )
    }
}
