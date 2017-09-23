//
//  PluginsTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import BaseFramework
import FirebaseAnalytics

class PluginCell: UITableViewCell {

    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var detailText: UILabel!
}

class PluginsTableViewController: UITableViewController {

    var searchController: UISearchController!
    var resultsTableController: PluginsSearchTableViewController!

    override func viewWillAppear(_ animated: Bool) {
        Analytics.logEvent("enter_screen", parameters: [
            "screen_name": "Plugins"
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.tableView.estimatedRowHeight = 80.0
        self.tableView.rowHeight = UITableViewAutomaticDimension

        resultsTableController = self.storyboard?.instantiateViewController(withIdentifier: "pluginsSearchTableViewController") as? PluginsSearchTableViewController

        // We want ourselves to be the delegate for this filtered table so didSelectRowAtIndexPath(_:) is called for both tables.

        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
        } else {
            searchController.searchBar.sizeToFit()
            tableView.tableHeaderView = searchController.searchBar
        }

        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = true // default is YES
        searchController.searchBar.delegate = self    // so we can monitor text changes + others

        NotificationCenter.default.addObserver(forName: ScriptsUpdatedNotification, object: nil, queue: OperationQueue.main) { _ in
            self.loadScripts()
            self.tableView.reloadData()
        }
        loadScripts()

        definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var scripts = [String: [Script]]()
    var keys = [String]()
    var allScripts = [Script]()

    var changed = false

    func loadScripts() {
        scripts = [String: [Script]]()
        keys = [String]()
        allScripts = [Script]()
        let temp = ScriptsManager.sharedInstance.storedPlugins
        for script in temp {
            if scripts[script.category] != nil {
                scripts[script.category]!.append(script)
            } else {
                scripts[script.category] = [script]
            }
        }
        keys = scripts.keys.sorted()
        if let index = keys.index(of: "Deleted") {
            keys.remove(at: index)
            keys.append("Deleted")
        }
        for key in keys {
            allScripts.append(contentsOf: scripts[key] ?? [Script]())
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if (self.changed) {
            NotificationCenter.default.post(name: JSNotificationReloadRequired, object: nil)
            self.changed = false
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scripts[keys[section]]?.count ?? 0
    }

    func configureCell(_ originCell: UITableViewCell, indexPath: IndexPath) {
        let script = scripts[keys[indexPath.section]]![indexPath.row]
        guard let cell = originCell as? PluginCell else {
            return
        }
        cell.titleText!.text = script.name
        cell.detailText!.text = script.scriptDescription
        let loaded = ScriptsManager.sharedInstance.loadedPlugins.contains(script.fileName)
        if loaded {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        // Populate cell from the NSManagedObject instance
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let script = scripts[keys[indexPath.section]]![indexPath.row]
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
        self.changed = true
        tableView.deselectRow(at: indexPath, animated: true)
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PluginCell", for: indexPath)

        self.configureCell(cell, indexPath: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return keys[section]
    }
}

extension PluginsTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UISearchControllerDelegate

    func presentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        self.tableView.reloadData()
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        //debugPrint("UISearchControllerDelegate invoked method: \(__FUNCTION__).")
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = searchController.searchBar.text!.trimmingCharacters(in: whitespaceCharacterSet)
        let searchItems = strippedString.components(separatedBy: " ") as [String]

        // Build all the "AND" expressions for each value in the searchString.
        let andMatchPredicates: [NSPredicate] = searchItems.map { searchString in
            // Each searchString creates an OR predicate for: name, category, scriptDescription.
            //
            // Example if searchItems contains "iphone 599 2007":
            //      name CONTAINS[c] "iphone"
            //      name CONTAINS[c] "599"
            //

            // Below we use NSExpression represent expressions in our predicates.
            // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value).

            // Name field matching.
            let nameExpression = NSExpression(forKeyPath: "name")
            let categoryExpression = NSExpression(forKeyPath: "category")
            let descriptionExpression = NSExpression(forKeyPath: "scriptDescription")
            let searchStringExpression = NSExpression(forConstantValue: searchString)

            let nameSearchComparisonPredicate = NSComparisonPredicate(leftExpression: nameExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
            let categorySearchComparisonPredicate = NSComparisonPredicate(leftExpression: categoryExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
            let descriptionSearchComparisonPredicate = NSComparisonPredicate(leftExpression: descriptionExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)

            // Add this OR predicate to our master AND predicate.
            let orMatchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [nameSearchComparisonPredicate, categorySearchComparisonPredicate, descriptionSearchComparisonPredicate])

            return orMatchPredicate
        }

        // Match up the fields of the Product object.
        let finalCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)

        let filteredScripts = allScripts.filter {
            finalCompoundPredicate.evaluate(with: $0)
        }

        // Hand over the filtered results to our search results table.
        let resultsController = searchController.searchResultsController as! PluginsSearchTableViewController
        resultsController.resultScripts = filteredScripts
        resultsController.tableView.reloadData()
    }
}
