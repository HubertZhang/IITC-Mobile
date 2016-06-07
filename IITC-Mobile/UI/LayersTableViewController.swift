//
//  LayersTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class LayersTableViewController: UITableViewController {

    let layersController = LayersController.sharedInstance
    var currentActiveIndex = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationLayersGot, object: nil)
        if let index = layersController.baseLayers.indexOf({ $0.active }) {
            currentActiveIndex = index
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateLayers() {
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch (section) {
        case 0:
            return 4;
        case 1:
            return layersController.baseLayers.count;
        case 2:
            return layersController.overlayLayers.count;
        default:
            break;
        }
        return 0;
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return "Panels";
        case 1:
            return "BASE LAYERS";
        case 2:
            return "OVERLAY LAYERS";
        default:
            break;
        }
        return ""
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
            case 0:
                cell.textLabel!.text = "Info";
                break;
            case 1:
                cell.textLabel!.text = "All";
                break;
            case 2:
                cell.textLabel!.text = "Faction";
                break;
            case 3:
                cell.textLabel!.text = "Alert";
                break;
            default:
                break;
            }

        case 1:
            let layer = layersController.baseLayers[indexPath.row]
            cell.textLabel!.text = layer.layerName
            if layer.active {
                cell.accessoryType = .Checkmark
            } else {
                cell.accessoryType = .None
            }
        case 2:
            let layer = layersController.overlayLayers[indexPath.row]
            cell.textLabel!.text = layer.layerName
            if layer.active {
                cell.accessoryType = .Checkmark
            } else {
                cell.accessoryType = .None
            }
        default:
            break;
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.section) {
        case 0:
            var panels = ["Info", "All", "Faction", "Alert"]
            NSNotificationCenter.defaultCenter().postNotificationName("SwitchToPanel", object: nil, userInfo: ["Panel": panels[indexPath.row]])
            self.dismiss(nil)
        case 1:
            let layer = layersController.baseLayers[indexPath.row]
            if layer.active {
                return
            } else {
                layer.active = true
                layersController.baseLayers[currentActiveIndex].active = false
                tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
                let newIndexPath = NSIndexPath(forRow: currentActiveIndex, inSection: indexPath.section)
                tableView.cellForRowAtIndexPath(newIndexPath)?.accessoryType = .None
                currentActiveIndex = indexPath.row
                NSNotificationCenter.defaultCenter().postNotificationName("WebViewExecuteJS", object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID))"])

            }
        case 2:
            let layer = layersController.overlayLayers[indexPath.row]
            if layer.active {
                layer.active = false
                tableView.cellForRowAtIndexPath(indexPath)!.accessoryType = .None
                NSNotificationCenter.defaultCenter().postNotificationName("WebViewExecuteJS", object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID), false)"])
            } else {
                layer.active = true
                tableView.cellForRowAtIndexPath(indexPath)!.accessoryType = .Checkmark
                NSNotificationCenter.defaultCenter().postNotificationName("WebViewExecuteJS", object: nil, userInfo: ["JS": "window.layerChooser.showLayer(\(layer.layerID), true)"])
            }
        default:
            break;
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
    @IBAction func dismiss(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


}
