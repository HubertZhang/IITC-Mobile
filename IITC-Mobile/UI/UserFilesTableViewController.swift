//
//  UserFilesTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/15.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import BaseFramework
import Alamofire
import MBProgressHUD

class FileCell: UITableViewCell {

}

class UserFilesTableViewController: UITableViewController {

    var contents = [NSURL]()
    var recordedUserScripts = Set<NSURL>()
    var userScriptsPath: NSURL!

    override func viewDidLoad() {
        super.viewDidLoad()
        userScriptsPath = ScriptsManager.sharedInstance.userScriptsPath
        NSNotificationCenter.defaultCenter().addObserverForName(ScriptsUpdatedNotification, object: nil, queue: NSOperationQueue.mainQueue()) {
            notification in
            self.updateContent()
            self.tableView.reloadData()
        }
        updateContent()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    func updateContent() {
        contents = []
        recordedUserScripts.removeAll()
        let temp = (try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(ScriptsManager.sharedInstance.userScriptsPath, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)) ?? []
        for url in temp {
            if url.lastPathComponent! == "com.google.iid-keypair.plist" {
                continue
            }
            contents.append(url.URLByResolvingSymlinksInPath!)
        }
        for script in ScriptsManager.sharedInstance.storedPlugins {
            if script.isUserScript {
                recordedUserScripts.insert(script.filePath)
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contents.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FileCell", forIndexPath: indexPath) as! FileCell

        // Configure the cell...
        let url = contents[indexPath.row]
        cell.textLabel?.text = url.lastPathComponent!
        if url == ScriptsManager.sharedInstance.mainScript.filePath {
            cell.detailTextLabel?.text = "Main IITC Script"
        } else if recordedUserScripts.contains(url) {
            cell.detailTextLabel?.text = "User Script"
        } else {
            cell.detailTextLabel?.text = ""
        }

        return cell
    }



    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }



    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let url = contents[indexPath.row]
            do {
                try NSFileManager.defaultManager().removeItemAtURL(url)
                updateContent()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            } catch {

            }
        }
    }

    @IBAction func addButtonClicked(sender: AnyObject) {
        var downloadPath = userScriptsPath.copy() as! NSURL
        let alert = UIAlertController(title: "Input URL to add new scripts", message: nil, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler {
            textField in

        }
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
            action in
            let urlString = alert.textFields![0].text ?? ""
            if let url = NSURL(string: urlString) {
                let hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true);
                hud.mode = MBProgressHUDMode.AnnularDeterminate;
                hud.labelText = "Downloading...";

                Alamofire.download(.GET, url, destination: {
                    (url, response) -> NSURL in
                    let pathComponent = response.suggestedFilename
                    downloadPath = downloadPath.URLByAppendingPathComponent(pathComponent!)
                    if NSFileManager.defaultManager().fileExistsAtPath(downloadPath.path!) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(downloadPath.path!)
                        } catch {

                        }
                    }
                    return downloadPath
                }).progress {
                    bytesRead, totalBytesRead, totalBytesExpectedToRead in

                    // This closure is NOT called on the main queue for performance
                    // reasons. To update your ui, dispatch to the main queue.
                    dispatch_async(dispatch_get_main_queue()) {
                        hud.progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    }
                }.response {
                    request, response, _, error in
                    hud.hide(true)
                    if error != nil {
                        let alert1 = UIAlertController(title: "Error", message: error!.description, preferredStyle: .Alert)
                        alert1.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                        self.presentViewController(alert1, animated: true, completion: nil)
                    }
                }
            } else {
                let alert1 = UIAlertController(title: "Error", message: "Not a legal URL", preferredStyle: .Alert)
                alert1.addAction(UIAlertAction(title: nil, style: .Cancel, handler: nil))
                self.presentViewController(alert1, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        self.presentViewController(alert, animated: true, completion: nil)

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
