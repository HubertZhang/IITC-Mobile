//
//  JSFileViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/6/21.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import Highlightr
import MBProgressHUD

class JSFileViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    var filePath: URL!
    var tempCode: NSAttributedString!

    @IBOutlet weak var viewPlaceHolder: UIView!
    var textView1: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        textView.autocorrectionType = UITextAutocorrectionType.no
        textView.autocapitalizationType = UITextAutocapitalizationType.none
        textView.textColor = UIColor(white: 0.8, alpha: 1.0)

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {

        let code = (try? String.init(contentsOf: self.filePath)) ?? "window"
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.global().async(execute: {
            let highlightr = Highlightr()!
            highlightr.setTheme(to: "paraiso-dark")
            self.tempCode = highlightr.highlight(code, as: "javascript")
            DispatchQueue.main.async(execute: {
                self.textView.attributedText = self.tempCode
                hud.hide(animated: true)
            })
        })
        if #available(iOS 11.0, *) {
            textView.textContainerInset.left = self.view.safeAreaInsets.left + 12
            textView.textContainerInset.right = self.view.safeAreaInsets.right + 12
        } else {
            textView.textContainerInset.left = 12
            textView.textContainerInset.right = 12
        }
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        textView.textContainerInset.left = self.view.safeAreaInsets.left + 12
        textView.textContainerInset.right = self.view.safeAreaInsets.right + 12
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
