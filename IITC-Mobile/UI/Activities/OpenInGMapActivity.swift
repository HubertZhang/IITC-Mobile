//
//  OpenInGMapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2018/1/15.
//  Copyright © 2018年 IITC. All rights reserved.
//

import UIKit
import BaseFramework

class OpenInGMapActivity: OpenIn3rdMapActivity {
    var ActivityType: String = "OpenInGMapActivity"

    var MapScheme: String = "comgooglemapsurl://"

    func constructURL() -> URL {
        return URL(string: "comgooglemapsurl://www.google.com/maps/search/?api=1&query=\(latLng.0),\(latLng.1)")!
    }

    override var activityTitle: String? {
        return "Open in Google Maps"
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "map_goodle_app_icon")
    }
}
