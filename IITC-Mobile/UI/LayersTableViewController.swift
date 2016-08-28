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
        hairLine.hidden = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationLayersGot, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationAddPane, object: nil)

        if let index = layersController.baseLayers.indexOf({ $0.active }) {
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

    func updateLayers() {
        self.panelTable.reloadData()
        self.baseLayerTable.reloadData()
        self.overlayLayerTable.reloadData()
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (tableView) {
        case panelTable:
            return layersController.panelNames.count;
        case baseLayerTable:
            return layersController.baseLayers.count;
        case overlayLayerTable:
            return layersController.overlayLayers.count;
        default:
            break;
        }
        return 0;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
        switch (tableView) {
        case panelTable:
            cell.textLabel?.text = layersController.panelLabels[indexPath.row]
            if let image = UIImage(named: layersController.panelIcons[indexPath.row]) {
                cell.imageView?.image = image
            } else {
                cell.imageView?.image = UIImage(named: "ic_action_new_event")
            }

        case baseLayerTable:
            let layer = layersController.baseLayers[indexPath.row]
            cell.textLabel!.text = layer.layerName
            if layer.active {
                cell.accessoryType = .Checkmark
            } else {
                cell.accessoryType = .None
            }
        case overlayLayerTable:
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

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (tableView) {
        case panelTable:
            NSNotificationCenter.defaultCenter().postNotificationName("SwitchToPanel", object: nil, userInfo: ["Panel": layersController.panelNames[indexPath.row]])
            self.dismiss(nil)
        case baseLayerTable:
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
        case overlayLayerTable:
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
    @IBAction func tabChanged(segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case 0:
            panelTable.hidden = false
            baseLayerTable.hidden = true
            overlayLayerTable.hidden = true
        case 1:
            panelTable.hidden = true
            baseLayerTable.hidden = false
            overlayLayerTable.hidden = true
        case 2:
            panelTable.hidden = true
            baseLayerTable.hidden = true
            overlayLayerTable.hidden = false
        default:
            break
        }
    }

    @IBAction func dismiss(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }


}
