//
//  LayersController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import BaseFramework

class Layer: Codable {
    var layerID: Int = -1
    var layerName: String = ""
    var active: Bool = false

    enum CodingKeys: String, CodingKey {
        case layerID = "layerId"
        case layerName = "name"
        case active = "active"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? container.decode(Int.self, forKey: .layerID) {
            layerID = id
        } else if let idString = try? container.decode(String.self, forKey: .layerID) {
            layerID = Int(idString) ?? -1
        }
        layerName = try container.decode(String.self, forKey: .layerName)
        active = (try? container.decode(Bool.self, forKey: .active)) ?? false
    }
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

    }

    @objc func setLayers(_ notification: Notification) {
        guard let layers = notification.userInfo?["layers"] as? [String] else {
            return
        }
        if layers.count != 2 {
            return
        }
        self.baseLayers = []
        self.overlayLayers = []
        do {
            let decoder = JSONDecoder()
            let tempLayers = try decoder.decode([Layer].self, from: layers[0].data(using: .utf8)!)
            for layer in tempLayers {
                baseLayers.append(layer)
            }
        } catch {
            print(error.localizedDescription)
        }
        do {
            let decoder = JSONDecoder()
            let tempLayers = try decoder.decode([Layer].self, from: layers[1].data(using: .utf8)!)
            for layer in tempLayers {
                overlayLayers.append(layer)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    @objc func addPane(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: String] else {
            return
        }
        if let name = info["name"], let label = info["label"] {
            self.panelNames.append(name)
            self.panelLabels.append(label)
            self.panelIcons.append(info["icon"] ?? "ic_action_new_event")
        }
    }

    @objc func reload(_ notification: Notification) {
        panelNames = ["info", "all", "faction", "alert"]
        panelLabels = ["Info", "All", "Faction", "Alert"]
        panelIcons = ["ic_action_about", "ic_action_view_as_list", "ic_action_cc_bcc", "ic_action_warning"]
    }

}
