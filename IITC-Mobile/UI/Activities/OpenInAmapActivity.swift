//
//  OpenInAmapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/8/9.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

class OpenInAmapActivity: OpenIn3rdMapActivity {
    var ActivityType: String = "OpenInAmapActivity"

    var MapScheme: String = "iosamap://"

    func constructURL() -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "iosamap"
        urlComponents.host = "viewMap"
        urlComponents.queryItems = [
            URLQueryItem(name: "dev", value: "1"),
            URLQueryItem(name: "title", value: title ?? "Portal"),
            URLQueryItem(name: "content", value: "Exported from IITC-iOS"),
            URLQueryItem(name: "lat", value: "\(latLng.0)"),
            URLQueryItem(name: "lng", value: "\(latLng.1)")
        ]
        return urlComponents.url!
    }

    override var activityTitle: String? {
        return "Open in Gaode Map"
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "map_amap_app_icon")
    }
}
