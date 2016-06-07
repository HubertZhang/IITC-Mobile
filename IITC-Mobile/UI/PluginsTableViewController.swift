//
//  PluginsTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class PluginCell: UITableViewCell {

    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var detailText: UILabel!
}

class PluginsTableViewController: UITableViewController {

//    var prototypeCell : PluginCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.tableView.estimatedRowHeight = 80.0
        self.tableView.rowHeight = UITableViewAutomaticDimension;
//        prototypeCell = self.tableView.dequeueReusableCellWithIdentifier("PluginCell") as! PluginCell
        loadScripts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var scripts = [String: [Script]]()
    var keys = [String]()
//    var heights = [String:[CGFloat]]()

    var changed = false
    func loadScripts() {
        let temp = ScriptsManager.sharedInstance.storedPlugins
        for script in temp {
//            prototypeCell.titleText.text = script.name
//            prototypeCell.detailText.text = script.scriptDescription
//            prototypeCell.setNeedsLayout()
//            prototypeCell.contentView.layoutIfNeeded()
//            let height = prototypeCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingExpandedSize).height + 1
            if scripts[script.category] != nil {
                scripts[script.category]!.append(script)
//                heights[script.category]!.append(height)
            } else {
                scripts[script.category] = [script]
//                heights[script.category] = [height]

            }

        }
        keys = scripts.keys.sort()
        if let index = keys.indexOf("Deleted") {
            keys.removeAtIndex(index)
            keys.append("Deleted")
        }

    }

    override func viewWillDisappear(animated: Bool) {
        if (self.changed) {
            NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationReloadRequired, object: nil);
            self.changed = false;
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return keys.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scripts[keys[section]]?.count ?? 0
    }

    func configureCell(originCell: UITableViewCell, indexPath: NSIndexPath) {
        let script = scripts[keys[indexPath.section]]![indexPath.row]
        let cell = originCell as! PluginCell
        cell.titleText!.text = script.name
        cell.detailText!.text = script.scriptDescription
        let loaded = ScriptsManager.sharedInstance.loadedPlugins.contains(script.fileName)
        if loaded {
            cell.accessoryType = .Checkmark;
        } else {
            cell.accessoryType = .None;
        }

        // Populate cell from the NSManagedObject instance
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let script = scripts[keys[indexPath.section]]![indexPath.row]
        let loaded = ScriptsManager.sharedInstance.loadedPlugins.contains(script.fileName)

        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if loaded {
            cell.accessoryType = .None;
        } else {
            cell.accessoryType = .Checkmark;
        }
        ScriptsManager.sharedInstance.setPlugin(script, loaded: !loaded)
        self.changed = true
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PluginCell", forIndexPath: indexPath)

        self.configureCell(cell, indexPath: indexPath)

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return keys[section]
    }

//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return heights[keys[indexPath.section]]![indexPath.row]
//    }
//    
//    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return heights[keys[indexPath.section]]![indexPath.row]
//    }

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

}
