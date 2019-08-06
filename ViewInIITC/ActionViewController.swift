//
//  ActionViewController.swift
//  ViewInIITC
//
//  Created by Hubert Zhang on 16/6/10.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import MobileCoreServices
import WebKit
import BaseFramework

class ActionViewController: UIViewController, URLSessionDelegate, URLSessionDownloadDelegate {
    private var observationProgress: NSKeyValueObservation?

    var webView: IITCWebView!
    var location = IITCLocation()
    var layersController: LayersController = LayersController.sharedInstance

    var url: URL = URL(string: "https://www.ingress.com/intel")!

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var webProgressView: UIProgressView!

    var loadIITCNeeded = true

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.vuryleo.iitcmobile.background")
        config.sharedContainerIdentifier = ContainerIdentifier
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func syncCookie() {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        let bakCookiePath = containerPath.appendingPathComponent("Library/Cookies/Cookies.binarycookies", isDirectory: false)
        if !FileManager.default.fileExists(atPath: bakCookiePath.path) {
            return
        }

        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
        let cookieDirPath = libraryPath.appendingPathComponent("Cookies", isDirectory: true)
        let cookiePath = cookieDirPath.appendingPathComponent("Cookies.binarycookies", isDirectory: false)

        if FileManager.default.fileExists(atPath: cookiePath.path) {
            do {
                try FileManager.default.removeItem(atPath: cookiePath.path)
                try FileManager.default.copyItem(at: bakCookiePath, to: cookiePath)
            } catch let error {
                debugPrint("error occurred, here are the details:\n \(error)")
            }
        } else {
            try? FileManager.default.createDirectory(at: cookieDirPath, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.copyItem(at: bakCookiePath, to: cookiePath)
        }
    }

    func handleJSFileURL(_ url: URL) {
        let alert = UIAlertController(title: "Save JS File to IITC?", message: "A JavaScript file detected. Would you like to save this file to IITC (as a Plugin)?\nURL:\(url.absoluteString)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            let task = self.session.downloadTask(with: url)
            task.resume()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        let userScriptsPath = containerPath.appendingPathComponent("userScripts", isDirectory: true)
        guard let filename = downloadTask.response?.suggestedFilename else {
            return
        }
//        print(filename)
        let destURL = userScriptsPath.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destURL)
        do {
            try FileManager.default.moveItem(at: location, to: destURL)
        } catch let e {
            print(e.localizedDescription)
        }
    }

    func configureWebView() {
        syncCookie()
        self.webView = IITCWebView(frame: CGRect.zero)
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView)

        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[top][v]|", options: [], metrics: nil, views: ["v": self.webView!, "top": self.topLayoutGuide]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|[v]|", options: [], metrics: nil, views: ["v": self.webView!]))

        self.observationProgress = self.webView.observe(\IITCWebView.estimatedProgress, changeHandler: { (webview, _) in
            let progress = webview.estimatedProgress
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
        self.view.bringSubviewToFront(webProgressView)
    }

    func configureNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(bootFinished), name: JSNotificationBootFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sharedAction(_:)), name: JSNotificationSharedAction, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "SwitchToPanel"), object: nil, queue: OperationQueue.main) {
            (notification) in
            guard let panel = notification.userInfo?["Panel"] as? String else {
                return
            }
            self.switchToPanel(panel)
        }
    }

    func extensionURLItemHandler(item: NSSecureCoding?, error: Error!) {
        guard let wrappedURL = item as? URL else {
            return
        }
        debugPrint(wrappedURL)
        if wrappedURL.host?.contains("ingress.com") ?? false {
            self.url = wrappedURL
            OperationQueue.main.addOperation {
                self.webView.load(URLRequest(url: wrappedURL))
            }
        } else if wrappedURL.host == "maps.apple.com" {
            var components = URLComponents(url: wrappedURL, resolvingAgainstBaseURL: false)!
            guard let queryItems = components.queryItems else {
                return
            }
            let ll = queryItems.filter({
                return $0.name == "ll"
            })
            if ll.count > 0 {
                var newURLComponents = URLComponents(string: "https://www.ingress.com/intel")!
                newURLComponents.queryItems = [ll[0]]
                if let newURL = newURLComponents.url {
                    OperationQueue.main.addOperation {
                        self.webView.load(URLRequest(url: newURL))
                    }
                }
            }
        } else if wrappedURL.pathExtension == "js" {
            OperationQueue.main.addOperation {
                self.webView.loadHTMLString("JSFile", baseURL: nil)
                self.handleJSFileURL(wrappedURL)
            }
        } else {
            OperationQueue.main.addOperation {
                self.webProgressView.isHidden = true
                self.webView.loadHTMLString("Link not supported:\(wrappedURL.absoluteString)", baseURL: nil)
            }
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureWebView()
        configureNotification()
        self.loadIITCNeeded = true
        var founded = false
        for item in self.extensionContext?.inputItems ?? [] where item is NSExtensionItem {
            guard let inputItem = item as? NSExtensionItem else {
                continue
            }
            for provider in inputItem.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    founded = true
                    provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: self.extensionURLItemHandler)
                }
            }
        }
        if !founded {
            self.webProgressView.isHidden = true
            self.webView.loadHTMLString("Link not supported", baseURL: nil)
        }
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    deinit {
        self.observationProgress = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backButtonPressed(_ sender: AnyObject) {
        if !self.backPanel.isEmpty {
            let panel = self.backPanel.removeLast()

            self.switchToPanel(panel)
            self.backButtonPressed = true
        }
        if self.backPanel.isEmpty {
            self.backButton.isEnabled = false
        }
    }

    @IBAction func reloadButtonPressed(_ aa: AnyObject) {
        reloadIITC()
    }

    @objc func bootFinished() {
        getLayers()
        self.webView.evaluateJavaScript("if(urlPortalLL[0] != undefined) window.selectPortalByLatLng(urlPortalLL[0],urlPortalLL[1]);")
    }

    var currentPanelID = "map"
    var backPanel = [String]()
    var backButtonPressed = false

    @objc func setCurrentPanel(_ notification: Notification) {
        guard let panel = (notification as NSNotification).userInfo?["paneID"] as? String else {
            return
        }

        if (panel == self.currentPanelID) {
            return
        }

        // map pane is top-lvl. clear stack.
        if (panel == "map") {
            self.backPanel.removeAll()
        }
        // don't push current pane to backstack if this method was called via back button
        else if (!self.backButtonPressed) {
            self.backPanel.append(self.currentPanelID)
            self.backButton.isEnabled = true
        }

        self.backButtonPressed = false
        self.currentPanelID = panel
    }

    func switchToPanel(_ pane: String) {
        self.webView.evaluateJavaScript(String(format: "window.show('%@')", pane))
    }

    @objc func reloadIITC() {
        self.loadIITCNeeded = true
        let userAgent = userDefaults.string(forKey: "pref_useragent")
        if userAgent != "" {
            self.webView.customUserAgent = userAgent
        }
        self.webView.load(URLRequest(url: url))
    }

    func getLayers() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
    }

    @objc func sharedAction(_ notification: Notification) {
        self.webView.evaluateJavaScript("window.dialog({text:\"Not supported in Action\"})")
    }
}

extension ActionViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //        print(#function)
        //        print(navigationAction.request.mainDocumentURL)
        if let urlString = navigationAction.request.mainDocumentURL?.absoluteString {
            if urlString.contains("google.com") {
                //                print("Allowed1")
                self.webView.configuration.userContentController.removeAllUserScripts()
                self.backPanel.removeAll()
                self.backButton.isEnabled = false
                self.loadIITCNeeded = true
            } else if urlString.contains("ingress.com/intel") && self.loadIITCNeeded {
                self.webView.configuration.userContentController.removeAllUserScripts()
                ScriptsManager.sharedInstance.reloadSettings()
                var scripts = ScriptsManager.sharedInstance.getLoadedScripts()
                let currentMode = IITCLocationMode(rawValue: userDefaults.integer(forKey: "pref_user_location_mode"))!
                if currentMode != .notShow {
                    scripts.append(ScriptsManager.sharedInstance.positionScript)
                }
                for script in scripts {
                    self.webView.configuration.userContentController.addUserScript(WKUserScript.init(source: script.fileContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
                }
                self.loadIITCNeeded = false
            }
        }
        decisionHandler(.allow)
    }
}

extension ActionViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
            _ -> Void in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: nil)
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
        self.present(alertController, animated: true, completion: nil)
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

}
