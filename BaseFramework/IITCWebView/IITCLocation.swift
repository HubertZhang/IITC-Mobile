//
//  IITCLocation.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import CoreLocation

enum IITCLocationMode: Int {
    case NotShow = 0
    case ShowPosition = 1
    case ShowPositionAndOrientation = 2
}

public class IITCLocation: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var currentMode = IITCLocationMode.NotShow
    
    var userDefaults = NSUserDefaults(suiteName: ContainerIdentifier)!
    public override init() {
        super.init()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

        // Set a movement threshold for new events.
        locationManager.distanceFilter = 1; // meters
        currentMode = IITCLocationMode(rawValue: userDefaults.integerForKey("pref_user_location_mode"))!
        if currentMode != .NotShow {
            self.startUpdate()
        }
        userDefaults.addObserver(self, forKeyPath: "pref_user_location_mode", options: .New, context: nil)

    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String:AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "pref_user_location_mode" {
            currentMode = IITCLocationMode(rawValue: userDefaults.integerForKey("pref_user_location_mode"))!
            if currentMode != .NotShow {
                self.startUpdate()
            } else {
                self.stopUpdate()
            }
        }
    }

    func startUpdate() {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
    }

    func stopUpdate() {
        locationManager.stopUpdatingLocation()
    }

    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = manager.location!
        var notification = ""
        if self.currentMode != .NotShow {
            notification = "if(window.plugin && window.plugin.userLocation)\nwindow.plugin.userLocation.onLocationChange(\(location.coordinate.latitude), \(location.coordinate.longitude));"
        }

        if self.currentMode == .ShowPositionAndOrientation {
            notification += "if(window.plugin && window.plugin.userLocation)\nwindow.plugin.userLocation.onOrientationChange(\(location.course));"
        }
        NSNotificationCenter.defaultCenter().postNotificationName("WebViewExecuteJS", object: nil, userInfo: ["JS": notification])

    }

    public func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        NSLog("Heading:%@", newHeading.description)
    }

    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("Error:%@", error.debugDescription)
    }
}
