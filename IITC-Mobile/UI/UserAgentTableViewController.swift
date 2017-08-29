//
//  UserAgentTableViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/8/29.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit

import BaseFramework

class MultiLineTextInputTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placeholder: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    weak var tableView: UITableView?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Custom setter so we can initialise the height of the text view
    var textString: String {
        get {
            return textView.text
        }
        set {
            textView.text = newValue
            
            textViewDidChange(textView)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Disable scrolling inside the text view so we enlarge to fitted size
        textView.isScrollEnabled = false
        textView.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            textView.becomeFirstResponder()
        } else {
            textView.resignFirstResponder()
        }
    }
}

extension MultiLineTextInputTableViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
            placeholder.text = " Default"
        } else {
            placeholder.text = ""
        }
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        // Resize the cell only when cell's size is changed
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            tableView?.beginUpdates()
            tableView?.endUpdates()
            UIView.setAnimationsEnabled(true)
            
            //if let thisIndexPath = tableView?.indexPathForCell(self) {
            //    tableView?.scrollToRowAtIndexPath(thisIndexPath, atScrollPosition: .Bottom, animated: false)
            //}
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UserDefaults(suiteName: ContainerIdentifier)!.set(textView.text, forKey: "pref_useragent")
    }
}

class PredefinedUserAgentCell : UITableViewCell {
    @IBOutlet weak var browserName: UILabel!
    @IBOutlet weak var userAgent: UILabel!
}

class UserAgentTableViewController: UITableViewController {

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!
    
    let predefinedUserAgents: [(String, String)] = [
        ("Safari iOS 10.3.1", "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Mobile/14E8301"),
        ("Chrome iOS 10.3.1", "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) CriOS/60.0.3112.89 Mobile/14E8301 Safari/602.1")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 60
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return predefinedUserAgents.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Current UserAgent"
        case 1:
            return "Predefined"
        default:
            return ""
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! MultiLineTextInputTableViewCell
            let userAgent = userDefaults.string(forKey: "pref_useragent") ?? ""
            if userAgent != "" {
                cell.textString = userAgent
            }
            cell.tableView = tableView
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PredefinedCell", for: indexPath) as! PredefinedUserAgentCell
            cell.browserName.text = predefinedUserAgents[indexPath.row].0
            cell.userAgent.text = predefinedUserAgents[indexPath.row].1

            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let cell = tableView.cellForRow(at: [0,0]) as! MultiLineTextInputTableViewCell
            cell.textString = predefinedUserAgents[indexPath.row].1
            
            UserDefaults(suiteName: ContainerIdentifier)!.set(predefinedUserAgents[indexPath.row].1, forKey: "pref_useragent")

        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
