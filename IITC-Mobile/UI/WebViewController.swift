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
        self.webView.isInspectable = true

        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView)

        NSLayoutConstraint.activate([
            self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        self.observationProgress = self.webView.observe(\WKWebView.estimatedProgress, changeHandler: { [weak self] (webview, _) in
            let progress = webview.estimatedProgress
            self?.webProgressView.setProgress(Float(progress), animated: true)
            if progress == 1.0 {
                UIView.animate(withDuration: 1, animations: {
                    () in
                    self?.webProgressView.alpha = 0
                }, completion: { _ in
                    self?.webProgressView.progress = 0
                })
            } else {
                self?.webProgressView.alpha = 1
            }
        })

        self.observationTitle = self.webView.observe(\WKWebView.title, changeHandler: { [weak self] (webView, _) in
            self?.title = webView.title
        })

        self.view.bringSubviewToFront(webProgressView)

        // Do any additional setup after loading the view.
    }

    deinit {
        self.observationTitle = nil
        self.observationProgress = nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
            _ in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: {
            () in
        })
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: {
            _ in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            _ in
            completionHandler(false)
        }))
        self.present(alertController, animated: true, completion: {
            () in
        })
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: prompt, message: webView.url!.host, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {
            (textField: UITextField) in
            textField.text = defaultText
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: {
            _  in
            let input = alertController.textFields!.first!.text!
            completionHandler(input)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            _  in
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
