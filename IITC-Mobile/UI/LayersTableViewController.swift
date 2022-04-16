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

    var layersController: LayersController!
    var currentActiveIndex = -1

    @IBOutlet weak var panelTable: UITableView!
    @IBOutlet weak var baseLayerTable: UITableView!
    @IBOutlet weak var overlayLayerTable: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    func configureHairline() {
        let app = UINavigationBarAppearance()
        app.shadowColor = .clear
        self.navigationBar.scrollEdgeAppearance = app
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureHairline()
        NotificationCenter.default.addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationLayersGot, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LayersTableViewController.updateLayers), name: JSNotificationAddPane, object: nil)

        if let index = layersController.baseLayers.firstIndex(where: { $0.active }) {
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
        switch tableView {
        case panelTable:
            return layersController.panels.count
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
        switch tableView {
        case panelTable:
            let panel = layersController.panels[indexPath.row]
            cell.textLabel?.text = panel.label
            let image = UIImage(named: panel.icon) ?? UIImage(named: "ic_action_new_event")
            cell.imageView?.image = image?.withRenderingMode(.alwaysTemplate)
            if #available(iOS 13.0, *) {
                cell.imageView?.tintColor = UIColor.label
            }
        case baseLayerTable:
            let layer = layersController.baseLayers[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = layer.layerName
            if layer.active {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        case overlayLayerTable:
            let layer = layersController.overlayLayers[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = layer.layerName
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
        tableView.deselectRow(at: indexPath, animated: true)
        switch tableView {
        case panelTable:
            let panel = layersController.panels[indexPath.row]
            layersController.openPanel(panel.id)
            self.dismiss(nil)
        case baseLayerTable:
            let layer = layersController.baseLayers[(indexPath as NSIndexPath).row]
            layersController.show(map: layer.layerID)
            baseLayerTable.reloadData()
        case overlayLayerTable:
            let layer = layersController.overlayLayers[(indexPath as NSIndexPath).row]
            layersController.show(overlay: layer.layerID)
            overlayLayerTable.reloadData()
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
