//
//  OpenInGMapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2018/1/15.
//  Copyright © 2018年 IITC. All rights reserved.
//

import UIKit
import BaseFramework

class OpenInGMapActivity: UIActivity {
    var url: URL?
    var title: String?
    var ll: (Double, Double)?

    override class var activityCategory: UIActivityCategory {
        return .share
    }

    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "OpenInGMapActivity")
    }

    override var activityTitle: String? {
        return "Open in Google Maps"
    }

    override var activityImage: UIImage? {
        return UIImage(named: "gmaps_app_icon")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        if !UIApplication.shared.canOpenURL(URL(string: "comgooglemapsurl://")!) {
            return false
        }

        if activityItems.count == 3 {
            if let url = activityItems[1] as? URL {
                return url.absoluteString.hasPrefix("https://www.ingress.com")
            }
        }
        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        if let title = activityItems[0] as? String {
            self.title = title
        }
        if let url = activityItems[1] as? URL {
            self.url = url
        }
        if let pos = activityItems[2] as? [String: Any] {
            guard var lat = pos["lat"] as? Double, var lng = pos["lng"] as? Double else {
                return
            }

            let userDefaults = UserDefaults(suiteName: ContainerIdentifier)!
            if userDefaults.bool(forKey: "pref_china_offset") {
                if !LocationTransform.isOutOfChina(lat: lat, lng: lng) {
                    (lat, lng) = LocationTransform.wgs2gcj(wgsLat: lat, wgsLng: lng)
                }
            }
            self.ll = (lat, lng)
        }
    }

    override func perform() {
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemapsurl://")!) {
            if let ll = self.ll {
                let url = URL(string: "comgooglemapsurl://www.google.com/maps/search/?api=1&query=\(ll.0),\(ll.1)")!
                UIApplication.shared.openURL(url)
            }
        }
        self.activityDidFinish(true)
    }
}
