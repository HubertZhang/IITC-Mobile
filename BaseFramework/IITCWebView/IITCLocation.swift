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

open class IITCLocation: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var currentMode = IITCLocationMode.notShow
    
    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!
    public override init() {
        super.init()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

        // Set a movement threshold for new events.
        locationManager.distanceFilter = 1; // meters
        currentMode = IITCLocationMode(rawValue: userDefaults.integer(forKey: "pref_user_location_mode"))!
        if currentMode != .notShow {
            self.startUpdate()
        }
        userDefaults.addObserver(self, forKeyPath: "pref_user_location_mode", options: .new, context: nil)

    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey:Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "pref_user_location_mode" {
            currentMode = IITCLocationMode(rawValue: userDefaults.integer(forKey: "pref_user_location_mode"))!
            if currentMode != .notShow {
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
    }

    func stopUpdate() {
        locationManager.stopUpdatingLocation()
    }

    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = manager.location!
        var notification = ""
        if self.currentMode != .notShow {
            notification = "if(window.plugin && window.plugin.userLocation)\nwindow.plugin.userLocation.onLocationChange(\(location.coordinate.latitude), \(location.coordinate.longitude));"
        }

        if self.currentMode == .showPositionAndOrientation {
            notification += "if(window.plugin && window.plugin.userLocation)\nwindow.plugin.userLocation.onOrientationChange(\(location.course));"
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": notification])

    }

    open func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        NSLog("Heading:%@", newHeading.description)
    }

    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Error:%@", error.localizedDescription)
    }
}
