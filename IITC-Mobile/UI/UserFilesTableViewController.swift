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

    var contents = [URL]()
    var recordedUserScripts = Set<URL>()
    var userScriptsPath: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        userScriptsPath = ScriptsManager.sharedInstance.userScriptsPath
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: ScriptsUpdatedNotification), object: nil, queue: OperationQueue.main) {
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
        let temp = (try? FileManager.default.contentsOfDirectory(at: ScriptsManager.sharedInstance.userScriptsPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
        for url in temp {
            if url.lastPathComponent == "com.google.iid-keypair.plist" {
                continue
            }
            contents.append(url.resolvingSymlinksInPath())
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contents.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as! FileCell

        // Configure the cell...
        let url = contents[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = url.lastPathComponent
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }



    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let url = contents[(indexPath as NSIndexPath).row]
            do {
                try FileManager.default.removeItem(at: url)
                updateContent()
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {

            }
        }
    }

    @IBAction func addButtonClicked(_ sender: AnyObject) {
        var downloadPath = userScriptsPath!
        let alert = UIAlertController(title: "Input URL to add new scripts", message: nil, preferredStyle: .alert)
        alert.addTextField {
            textField in

        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
            let urlString = alert.textFields![0].text ?? ""
            if let url = URL(string: urlString) {
                let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true);
                hud.mode = MBProgressHUDMode.annularDeterminate;
                hud.label.text = "Downloading...";

                Alamofire.download(url as URLStringConvertible, to: {
                    (url, response) -> URL in
                    let pathComponent = response.suggestedFilename
                    downloadPath = downloadPath.appendingPathComponent(pathComponent!)
                    if FileManager.default.fileExists(atPath: downloadPath.path) {
                        do {
                            try FileManager.default.removeItem(atPath: downloadPath.path)
                        } catch {

                        }
                    }
                    return downloadPath
                }, withMethod: .get , parameters: nil, encoding: ParameterEncoding.url, headers: nil).progress {
                    bytesRead, totalBytesRead, totalBytesExpectedToRead in

                    // This closure is NOT called on the main queue for performance
                    // reasons. To update your ui, dispatch to the main queue.
                    DispatchQueue.main.async {
                        hud.progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    }
                }.response {
                    request, response, _, error in
                    hud.hide(animated: true)
                    if error != nil {
                        let alert1 = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .alert)
                        alert1.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alert1, animated: true, completion: nil)
                    }
                }
            } else {
                let alert1 = UIAlertController(title: "Error", message: "Not a legal URL", preferredStyle: .alert)
                alert1.addAction(UIAlertAction(title: nil, style: .cancel, handler: nil))
                self.present(alert1, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)

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
