//
//  WhatsNewViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/22.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class WhatsNewViewController: UIViewController, UITextViewDelegate {
    
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewWillAppear(_ animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "WhatsNew")
        
        let builder = GAIDictionaryBuilder.createScreenView()!
        tracker?.send(builder.build() as Dictionary)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.url(forResource: "WhatsNew", withExtension: "html")
        let htmlString = try! String(contentsOf: path!)
        guard let data = htmlString.data(using: String.Encoding.utf8) else {
            return
        }
        let options : [String:Any] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSNumber(value:String.Encoding.utf8.rawValue)]
        textView.attributedText = try! NSAttributedString(data:data, options:options, documentAttributes: nil)
        textView.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
