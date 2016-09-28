//
//  OpenInMapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/8.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import MapKit
import BaseFramework

class OpenInMapActivity: UIActivity {
    var url: URL?
    var title: String?
    var mapItem: MKMapItem?
    
    override class var activityCategory : UIActivityCategory {
        return .share
    }
    
    override var activityType : UIActivityType? {
        return UIActivityType(rawValue: "OpenInMapActivity")
    }
    
    override var activityTitle : String? {
        return "Maps"
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "maps_app_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
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
        if let pos = activityItems[2] as? [AnyObject] {
            var lat = pos[0] as! Double
            var lng = pos[1] as! Double
            let userDefaults = UserDefaults(suiteName: ContainerIdentifier)!
            if userDefaults.bool(forKey: "pref_china_offset") {
                if LocationTransform.isOutOfChina(lat:lat, lng: lng) {
                    (lat, lng) = LocationTransform.wgs2gcj(wgsLat:lat, wgsLng: lng)
                }
            }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        }
    }
    
    override func perform() {
        self.mapItem?.name = self.title
        self.mapItem?.openInMaps(launchOptions: nil)
        self.activityDidFinish(true)
    }
}
