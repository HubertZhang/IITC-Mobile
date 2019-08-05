//
//  WebViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2016/9/30.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    private var observationProgress: NSKeyValueObservation?
    private var observationTitle: NSKeyValueObservation?

    var configuration: WKWebViewConfiguration?
    var webView: WKWebView!
    @IBOutlet weak var webProgressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if configuration != nil {
            self.webView = WKWebView(frame: CGRect.zero, configuration: configuration!)
        } else {
            self.webView = WKWebView(frame: CGRect.zero)
        }

        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView)

        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[top][v]|", options: [], metrics: nil, views: ["v": self.webView!, "top": self.topLayoutGuide]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|[v]|", options: [], metrics: nil, views: ["v": self.webView!]))

        self.observationProgress = self.webView.observe(\WKWebView.estimatedProgress, changeHandler: { (_, change) in
            guard let progress = change.newValue else {
                return
            }
            self.webProgressView.setProgress(Float(progress), animated: true)
            if progress == 1.0 {
                UIView.animate(withDuration: 1, animations: {
                    () -> Void in
                    self.webProgressView.alpha = 0
                }, completion: { _ in
                    self.webProgressView.progress = 0
                })
            } else {
                self.webProgressView.alpha = 1
            }
        })

        self.observationTitle = self.webView.observe(\WKWebView.title, changeHandler: { (webView, _) in
            self.title = webView.title
        })

        self.view.bringSubviewToFront(webProgressView)

        // Do any additional setup after loading the view.
    }

    deinit {
        self.observationTitle = nil
        self.observationProgress = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
            _ -> Void in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: {
            () -> Void in
        })
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: {
            _ -> Void in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            _ -> Void in
            completionHandler(false)
        }))
        self.present(alertController, animated: true, completion: {
            () -> Void in
        })
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: prompt, message: webView.url!.host, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {
            (textField: UITextField) -> Void in
            textField.text = defaultText
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: {
            _ -> Void in
            let input = alertController.textFields!.first!.text!
            completionHandler(input)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            _ -> Void in
            completionHandler(nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    func webViewDidClose(_ webView: WKWebView) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func closeButtonClicked(_: AnyObject) {
        self.dismiss(animated: true, completion: nil)
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
