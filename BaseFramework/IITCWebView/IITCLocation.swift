//
//  IITCLocation.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import CoreLocation

public enum IITCLocationMode: Int {
    case notShow = 0
    case showPosition = 1
    case showPositionAndOrientation = 2
}

extension UserDefaults {
    @objc dynamic var pref_user_location_mode: Int {
        return integer(forKey: "pref_user_location_mode")
    }
}

open class IITCLocation: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var currentMode = IITCLocationMode.notShow

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    private var defaultObservation: NSKeyValueObservation?
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        // Set a movement threshold for new events.
        locationManager.distanceFilter = 1
        // meters
        currentMode = IITCLocationMode(rawValue: userDefaults.pref_user_location_mode)!
        if currentMode != .notShow {
            self.startUpdate()
        }
        defaultObservation = userDefaults.observe(\.pref_user_location_mode) { (ud, _) in
            self.currentMode = IITCLocationMode(rawValue: ud.pref_user_location_mode)!
            if self.currentMode != .notShow {
                self.startUpdate()
            } else {
                self.stopUpdate()
            }
        }
    }

    func startUpdate() {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopUpdate() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = manager.location!
        var notification = ""
        if self.currentMode != .notShow {
            notification = "if(window.plugin && window.plugin.userLocation)\nwindow.plugin.userLocation.onLocationChange(\(location.coordinate.latitude), \(location.coordinate.longitude));"
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": notification])

    }

    open func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        var notification = ""
        if self.currentMode == .showPositionAndOrientation {
            if newHeading.headingAccuracy < 0 {
                return
            }
            notification += "if(window.plugin && window.plugin.userLocation)\nwindow.plugin.userLocation.onOrientationChange(\(newHeading.magneticHeading));"
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": notification])
    }

    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
