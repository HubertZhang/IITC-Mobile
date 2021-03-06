//
//  PluginsSearchTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/9/23.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import BaseFramework

class PluginsSearchTableViewController: UITableViewController {

    var resultScripts = [Script]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
//        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.estimatedRowHeight = 80.0
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultScripts.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let script = resultScripts[indexPath.row]
        let loaded = ScriptsManager.sharedInstance.loadedPlugins.contains(script.fileName)

        let cell = tableView.cellForRow(at: indexPath)!
        if loaded {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }
        tableView.beginUpdates()
        tableView.endUpdates()
        ScriptsManager.sharedInstance.setPlugin(script, loaded: !loaded)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalCell = tableView.dequeueReusableCell(withIdentifier: "PluginCell", for: indexPath)
        guard let cell = originalCell as? PluginCell else {
            return originalCell
        }
        let script = resultScripts[indexPath.row]
        configure(cell: cell, by: script)

        return cell
    }
}
