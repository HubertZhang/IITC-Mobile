//
//  LayersController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import BaseFramework

class Layer: NSObject {
    var layerID: Int = -1
    var layerName: String = ""
    var active: Bool = false
}

class LayersController: NSObject {
    static let sharedInstance = LayersController()

    var baseLayers = [Layer]()
    var overlayLayers = [Layer]()


    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LayersController.setLayers(_:)), name: JSNotificationLayersGot, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func setLayers(notification: NSNotification) {
        guard let layers = notification.userInfo?["layers"] as? [AnyObject] else {
            return
        }
        self.baseLayers = []
        self.overlayLayers = []
        if let tempLayers = (try? NSJSONSerialization.JSONObjectWithData((String(layers[0])).dataUsingEncoding(NSASCIIStringEncoding)!, options: .AllowFragments)) as? [AnyObject] {
            for tempLayer in tempLayers {
                if let layer = tempLayer as? [String:AnyObject] {
                    let layerObject = Layer()
                    layerObject.layerName = layer["name"] as! String
                    layerObject.layerID = (layer["layerId"] as! NSNumber).integerValue
                    layerObject.active = layer["active"] as! Bool
                    baseLayers.append(layerObject)
                }
            }
        }
        if let tempLayers = (try? NSJSONSerialization.JSONObjectWithData((String(layers[1])).dataUsingEncoding(NSASCIIStringEncoding)!, options: .AllowFragments)) as? [AnyObject] {
            for layer in tempLayers {
                if let layer = layer as? [String:AnyObject] {
                    let layerObject = Layer()
                    layerObject.layerName = layer["name"] as! String
                    layerObject.layerID = (layer["layerId"] as! NSNumber).integerValue
                    layerObject.active = layer["active"] as! Bool
                    overlayLayers.append(layerObject)
                }
            }
        }
    }

}
