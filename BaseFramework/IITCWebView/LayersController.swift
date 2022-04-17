//
//  LayersController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import Combine

open class Layer: Codable {
    open var layerID: Int = -1
    open var layerName: String = ""
    open var active: Bool = false

    enum CodingKeys: String, CodingKey {
        case layerID = "layerId"
        case layerName = "name"
        case active = "active"
    }

    required public init(from decoder: Decoder) throws {
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

public struct Panel: Identifiable, Hashable {
    public var id: String
    public var label: String
    public var icon: String

    public static var info = Panel(id: "info", label: "Info", icon: "ic_action_about")
    public static var all = Panel(id: "all", label: "All", icon: "ic_action_view_as_list")
    public static var faction = Panel(id: "faction", label: "Faction", icon: "ic_action_cc_bcc")
    public static var alerts = Panel(id: "alerts", label: "Alerts", icon: "ic_action_warning")

    public static func initialPanels() -> [Panel] {
        return [.info, .all, .faction, .alerts]
    }
}

public class LayersController: NSObject {
    public static let sharedInstance = LayersController()

    @Published public private(set) var baseLayers = [Layer]()
    @Published public private(set) var overlayLayers = [Layer]()
    @Published public private(set) var panels: [Panel] = Panel.initialPanels()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(LayersController.setLayers(_:)), name: JSNotificationLayersGot, object: nil)
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
            self.panels.append(Panel(id: name, label: label, icon: info["icon"] ?? "ic_action_new_event"))
        }
    }

    @objc func reload(_ notification: Notification) {
        reset()
    }

    func reset() {
        panels = Panel.initialPanels()
    }

    public func openPanel(_ id: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SwitchToPanel"), object: nil, userInfo: ["Panel": id])
    }

    public func show(map mapId: Int) {
        guard let layer = self.baseLayers.first(where: { $0.layerID == mapId }) else {
            return
        }
        if layer.active {
            return
        }
        _ = self.baseLayers.first { l in
            if l.active {
                l.active = false
                layer.active = true
                return true
            }
            return false
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID))"])
    }

    public func show(overlay overlayId: Int) {
        guard let layer = self.overlayLayers.first(where: { $0.layerID == overlayId }) else {
            return
        }
        layer.active = !layer.active
        let s = layer.active ? "true" : "false"
        NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID), \(s))"])
    }
}
