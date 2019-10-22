//
//  ConsoleSuggestionTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/22.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

protocol ConsoleSuggestionTableViewDelegate: class {
    func choose(suggestion: String)
}

class ConsoleSuggestionTableViewController: UITableViewController {

    weak var delegate: ConsoleSuggestionTableViewDelegate?

    var suggestions: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        self.tableView.rowHeight = 36
        self.tableView.allowsSelection = true
        self.tableView.bounces = false
        self.tableView.backgroundColor = UIColor.gray
    }

    func update(suggestions: [String]) {
        self.suggestions = suggestions
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.suggestions.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "defaultCell")

        cell.indentationLevel = 1
        cell.textLabel?.text = self.suggestions[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        if #available(iOS 13.0, *) {
            cell.backgroundColor = UIColor.secondarySystemBackground
        } else {
            cell.backgroundColor = UIColor.gray
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.delegate?.choose(suggestion: self.suggestions[indexPath.row])
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
