//
//  OpenInMapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/8.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import MapKit

class OpenInMapActivity: UIActivity {
    var url: NSURL?
    var title: String?
    var mapItem: MKMapItem?
    
    override class func activityCategory() -> UIActivityCategory {
        return .Share
    }
    
    override func activityType() -> String? {
        return "OpenInMapActivity"
    }
    
    override func activityTitle() -> String? {
        return "Maps"
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "maps_app_icon")
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        if activityItems.count == 3 {
            if let url = activityItems[1] as? NSURL {
                return url.absoluteString.hasPrefix("https://www.ingress.com")
            }
        }
        return false
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        if let title = activityItems[0] as? String {
            self.title = title
        }
        if let url = activityItems[1] as? NSURL {
            self.url = url
        }
        if let pos = activityItems[2] as? [AnyObject] {
            let lat = pos[0] as! Double
            let lng = pos[1] as! Double
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            self.mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        }
    }
    
    override func performActivity() {
        self.mapItem?.name = self.title
        self.mapItem?.openInMapsWithLaunchOptions(nil)
        self.activityDidFinish(true)
    }
}
