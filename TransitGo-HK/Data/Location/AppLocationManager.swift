//
//  AppLocationManager.swift
//  TransitGo-HK
//
//  Created by Ken on 14/8/2026.
//

import Foundation
import CoreLocation
import Observation

@Observable
final class AppLocationManager: NSObject,
                                CLLocationManagerDelegate {

    private let manager =
        CLLocationManager()

    private(set) var location: CLLocation?
    private(set) var authorizationStatus:
        CLAuthorizationStatus = .notDetermined

    private(set) var error: Error?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy =
            kCLLocationAccuracyNearestTenMeters

        authorizationStatus =
            manager.authorizationStatus
    }

    func requestLocation() {

        switch manager.authorizationStatus {

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse,
             .authorizedAlways:
            manager.requestLocation()

        case .restricted,
             .denied:
            break

        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        authorizationStatus =
            manager.authorizationStatus

        switch manager.authorizationStatus {

        case .authorizedWhenInUse,
             .authorizedAlways:
            manager.requestLocation()

        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        location =
            locations.last
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        self.error = error
    }
}
