//
//  LayersTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import BaseFramework

class LayersTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIToolbarDelegate {

    let layersController = LayersController.sharedInstance
    var currentActiveIndex = -1

    @IBOutlet weak var panelTable: UITableView!
    @IBOutlet weak var baseLayerTable: UITableView!
    @IBOutlet weak var overlayLayerTable: UITableView!

    var hairLine: UIView = UIView()

    func configureHairline() {
        for parent in self.navigationController!.navigationBar.subviews {
            for childView in parent.subviews {
                if childView is UIImageView && childView.bounds.size.width == self.navigationController!.navigationBar.frame.size.width {
                    hairLine = childView
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureHairline()
        hairLine.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationLayersGot, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationAddPane, object: nil)

        if let index = layersController.baseLayers.index(where: { $0.active }) {
            currentActiveIndex = index
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

//    override func viewWillAppear(animated: Bool) {
//        hairLine.hidden = true
//    }
//    
//    override func viewDidDisappear(animated: Bool) {
//        hairLine.hidden = false
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func updateLayers() {
        self.panelTable.reloadData()
        self.baseLayerTable.reloadData()
        self.overlayLayerTable.reloadData()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (tableView) {
        case panelTable:
            return layersController.panelNames.count
        case baseLayerTable:
            return layersController.baseLayers.count
        case overlayLayerTable:
            return layersController.overlayLayers.count
        default:
            break
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        switch (tableView) {
        case panelTable:
            cell.textLabel?.text = layersController.panelLabels[(indexPath as NSIndexPath).row]
            if let image = UIImage(named: layersController.panelIcons[(indexPath as NSIndexPath).row]) {
                cell.imageView?.image = image
            } else {
                cell.imageView?.image = UIImage(named: "ic_action_new_event")
            }

        case baseLayerTable:
            let layer = layersController.baseLayers[(indexPath as NSIndexPath).row]
            cell.textLabel!.text = layer.layerName
            if layer.active {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        case overlayLayerTable:
            let layer = layersController.overlayLayers[(indexPath as NSIndexPath).row]
            cell.textLabel!.text = layer.layerName
            if layer.active {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (tableView) {
        case panelTable:
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SwitchToPanel"), object: nil, userInfo: ["Panel": layersController.panelNames[(indexPath as NSIndexPath).row]])
            tableView.deselectRow(at: indexPath, animated: true)
            self.dismiss(nil)
        case baseLayerTable:
            tableView.deselectRow(at: indexPath, animated: true)
            let layer = layersController.baseLayers[(indexPath as NSIndexPath).row]
            if layer.active {
                return
            } else {
                layer.active = true
                layersController.baseLayers[currentActiveIndex].active = false
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                let newIndexPath = IndexPath(row: currentActiveIndex, section: (indexPath as NSIndexPath).section)
                tableView.cellForRow(at: newIndexPath)?.accessoryType = .none
                currentActiveIndex = (indexPath as NSIndexPath).row
                NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID))"])

            }
        case overlayLayerTable:
            let layer = layersController.overlayLayers[(indexPath as NSIndexPath).row]
            if layer.active {
                layer.active = false
                tableView.cellForRow(at: indexPath)!.accessoryType = .none
                NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID), false)"])
            } else {
                layer.active = true
                tableView.cellForRow(at: indexPath)!.accessoryType = .checkmark
                NotificationCenter.default.post(name: Notification.Name(rawValue: "WebViewExecuteJS"), object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID), true)"])
            }
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func tabChanged(_ segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case 0:
            panelTable.isHidden = false
            baseLayerTable.isHidden = true
            overlayLayerTable.isHidden = true
        case 1:
            panelTable.isHidden = true
            baseLayerTable.isHidden = false
            overlayLayerTable.isHidden = true
        case 2:
            panelTable.isHidden = true
            baseLayerTable.isHidden = true
            overlayLayerTable.isHidden = false
        default:
            break
        }
    }

    @IBAction func dismiss(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }


}
