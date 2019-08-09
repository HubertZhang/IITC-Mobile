//
//  OpenInBaiduMapActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/8/9.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

class OpenInBaiduMapActivity: OpenIn3rdMapActivity {
    var ActivityType: String = "OpenInBaiduMapActivity"

    var MapScheme: String = "baidumap://"

    func constructURL() -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "baidumap"
        urlComponents.host = "map"
        urlComponents.path = "/marker"
        urlComponents.queryItems = [
            URLQueryItem(name: "coord_type", value: "wgs84"),
            URLQueryItem(name: "title", value: title ?? "Portal"),
            URLQueryItem(name: "content", value: ""),
            URLQueryItem(name: "location", value: "\(latLng.0),\(latLng.1)")
        ]
        return urlComponents.url!
    }

    override var activityTitle: String? {
        return "Open in Baidu Map"
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "map_baidu_app_icon")
    }
}
