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

    var highlightr = Highlightr.init()!
    @IBOutlet weak var textView: UITextView!
    var filePath: URL!
    var tempCode: NSAttributedString!

    @IBOutlet weak var viewPlaceHolder: UIView!
    var textView1: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        highlightr.setTheme(to: "paraiso-dark")
        textView.autocorrectionType = UITextAutocorrectionType.no
        textView.autocapitalizationType = UITextAutocapitalizationType.none
        textView.textColor = UIColor(white: 0.8, alpha: 1.0)

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {

        let code = (try? String.init(contentsOf: self.filePath)) ?? "window"
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.global().async(execute: {
            self.tempCode = self.highlightr.highlight(code, as: "js")
            DispatchQueue.main.async(execute: {
                self.textView.attributedText = self.tempCode
                hud.hide(animated: true)
            })
        })
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
