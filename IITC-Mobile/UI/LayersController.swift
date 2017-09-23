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
    var panelNames = ["info", "all", "faction", "alerts"]
    var panelLabels = ["Info", "All", "Faction", "Alerts"]
    var panelIcons = ["ic_action_about", "ic_action_view_as_list", "ic_action_cc_bcc", "ic_action_warning"]

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(LayersController.setLayers(_:)), name: JSNotificationLayersGot, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LayersController.reload(_:)), name: JSNotificationReloadRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LayersController.addPane(_:)), name: JSNotificationAddPane, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setLayers(_ notification: Notification) {
        guard let layers = notification.userInfo?["layers"] as? [String] else {
            return
        }
        self.baseLayers = []
        self.overlayLayers = []
        if let tempLayers = (try? JSONSerialization.jsonObject(with: layers[0].data(using: .utf8)!, options: .allowFragments)) as? [[String: Any]] {
            for layer in tempLayers {
                let layerObject = Layer()
                guard let name = layer["name"] as? String, let ID = layer["layerId"] as? NSNumber, let actived = layer["active"] as? Bool else {
                    continue
                }
                layerObject.layerName = name
                layerObject.layerID = ID.intValue
                layerObject.active = actived
                baseLayers.append(layerObject)
            }
        }
        if let tempLayers = (try? JSONSerialization.jsonObject(with: layers[1].data(using: .utf8)!, options: .allowFragments)) as? [[String: Any]] {
            for layer in tempLayers {
                let layerObject = Layer()
                guard let name = layer["name"] as? String, let ID = layer["layerId"] as? NSNumber, let actived = layer["active"] as? Bool else {
                    continue
                }
                layerObject.layerName = name
                layerObject.layerID = ID.intValue
                layerObject.active = actived
                overlayLayers.append(layerObject)
            }
        }
    }

    func addPane(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: String] else {
            return
        }
        self.panelNames.append(info["name"]!)
        self.panelLabels.append(info["label"]!)
        self.panelIcons.append(info["icon"] ?? "ic_action_new_event")
    }

    func reload(_ notification: Notification) {
        panelNames = ["info", "all", "faction", "alert"]
        panelLabels = ["Info", "All", "Faction", "Alert"]
        panelIcons = ["ic_action_about", "ic_action_view_as_list", "ic_action_cc_bcc", "ic_action_warning"]
    }

}
