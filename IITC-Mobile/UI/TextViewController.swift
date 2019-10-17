//
//  TextViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/8.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import FirebaseAnalytics

func loadHtmlFileToAttributeString(_ path: URL) -> NSAttributedString? {
    let htmlData = try? Data(contentsOf: path)
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
    ]
    return try? NSAttributedString(data: htmlData!, options: options, documentAttributes: nil)
}


class TextViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    var attrStringBuilder: (() -> NSAttributedString?)?

    override func viewWillAppear(_ animated: Bool) {
        Analytics.logEvent("enter_screen", parameters: [
            "screen_name": self.title ?? "TextView"
        ])
        if #available(iOS 11.0, *) {
            textView.textContainerInset.left = self.view.safeAreaInsets.left + 12
            textView.textContainerInset.right = self.view.safeAreaInsets.right + 12
        } else {
            textView.textContainerInset.left = 12
            textView.textContainerInset.right = 12
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.attributedText = self.attrStringBuilder?()
        if #available(iOS 13.0, *) {
            textView.textColor = UIColor.label
        } else {
            // Fallback on earlier versions
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(CGPoint.zero, animated: false)
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        textView.textContainerInset.left = self.view.safeAreaInsets.left + 12
        textView.textContainerInset.right = self.view.safeAreaInsets.right + 12
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
