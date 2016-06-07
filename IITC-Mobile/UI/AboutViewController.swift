//
//  AboutViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/8.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController, UITextViewDelegate {


    @IBOutlet weak var textView: UITextView!
    
    override func viewWillAppear(animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "About")
            
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = NSBundle.mainBundle().URLForResource("About", withExtension: "html")
        let htmlString = try! String(contentsOfURL: path!)
        guard let data = htmlString.dataUsingEncoding(NSUTF8StringEncoding) else {
            return
        }
        let options : [String:AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding]
        textView.attributedText = try! NSAttributedString(data:data, options:options, documentAttributes: nil)
        // Do any additional setup after loading the view.
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
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
