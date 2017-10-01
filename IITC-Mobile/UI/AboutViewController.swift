//
//  AboutViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/8.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class AboutViewController: UIViewController, UITextViewDelegate {


    @IBOutlet weak var textView: UITextView!

    override func viewWillAppear(_ animated: Bool) {
        Analytics.logEvent("enter_screen", parameters: [
            "screen_name": "About"
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

        let path = Bundle.main.url(forResource: "About", withExtension: "html")
        let htmlString = try? String(contentsOf: path!)
        guard let data = htmlString?.data(using: String.Encoding.utf8) else {
            return
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)]
        textView.attributedText = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
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
