//
//  OpenIn3rdMapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/8/9.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit
import BaseFramework

protocol OpenIn3rdMapProtocol {
    var ActivityType: String { get }
    var MapScheme: String { get }

    func constructURL() -> URL
}

typealias OpenIn3rdMapActivity = OpenIn3rdMapProtocol & OpenIn3rdMapActivityClass

class OpenIn3rdMapActivityClass: UIActivity {
    var title: String?
    var portalURL: URL?
    var latLng: (Double, Double)!

    override class var activityCategory: UIActivity.Category {
        return .share
    }

    override var activityType: UIActivity.ActivityType? {
        guard let self = self as? OpenIn3rdMapProtocol else {
            return UIActivity.ActivityType(rawValue: "OpenIn3rdActivity")
        }
        return UIActivity.ActivityType(rawValue: self.ActivityType)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard let self = self as? OpenIn3rdMapProtocol else {
            return false
        }
        if !UIApplication.shared.canOpenURL(URL(string: self.MapScheme)!) {
            return false
        }

        if activityItems.count == 3 {
            if let pos = activityItems[2] as? [String: Any] {
                if !(pos["lat"] is Double && pos["lng"] is Double) {
                    return false
                }
                return true
            }
        }
        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        if let title = activityItems[0] as? String {
            self.title = title
        }
        if let url = activityItems[1] as? URL {
            self.portalURL = url
        }
        if let pos = activityItems[2] as? [String: Any] {
            guard let lat = pos["lat"] as? Double, let lng = pos["lng"] as? Double else {
                return
            }
            self.latLng = (lat, lng)
        }
    }

    override func perform() {
        guard let p = self as? OpenIn3rdMapProtocol else {
            self.activityDidFinish(true)
            return
        }
        if UIApplication.shared.canOpenURL(URL(string: p.MapScheme)!) {
            let url = p.constructURL()
            UIApplication.shared.open(url)
        }
        self.activityDidFinish(true)
    }

}
