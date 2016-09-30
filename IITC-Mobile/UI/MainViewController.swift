//
//  MainViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit
import BaseFramework
class MainViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var webView: IITCWebView!

    var layersController: LayersController = LayersController.sharedInstance
    
    var location = IITCLocation()
    
    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!
    
    var permalink: String = ""
    
    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var webProgressView: UIProgressView!


    var loadIITCNeeded = true

    func loadScripts() {
        var scripts = ScriptsManager.sharedInstance.getLoadedScripts()
        let currentMode = IITCLocationMode(rawValue: userDefaults.integer(forKey: "pref_user_location_mode"))!
        if currentMode != .notShow {
            scripts.append(ScriptsManager.sharedInstance.positionScript)
            
        }
        self.webView.loadScripts(scripts)
        loadIITCNeeded = false
        syncCookie()
    }
    
    func syncCookie() {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        let cookieDirPath = containerPath.appendingPathComponent("Library/Cookies", isDirectory: true)
        let bakCookiePath = cookieDirPath.appendingPathComponent("Cookies.binarycookies", isDirectory: false)
        if FileManager.default.fileExists(atPath: bakCookiePath.path) {
            return
        }
        
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
        let oriCookiePath = libraryPath.appendingPathComponent("Cookies/Cookies.binarycookies", isDirectory: false)
        if !FileManager.default.fileExists(atPath: oriCookiePath.path) {
            return
        }
        try? FileManager.default.createDirectory(at: cookieDirPath, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.copyItem(at: oriCookiePath, to: bakCookiePath)
    }

    func configureWebView() {
        self.webView = IITCWebView(frame: CGRect.zero)

        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView);

        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint.init(item: self.topLayoutGuide, attribute: .bottom, relatedBy: .equal, toItem: self.webView, attribute: .top, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.bottomLayoutGuide, attribute: .top, relatedBy: .equal, toItem: self.webView, attribute: .bottom, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .leading, relatedBy: .equal, toItem: self.webView, attribute: .leading, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: self.webView, attribute: .trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraints(constraints)

        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.view.bringSubview(toFront: webProgressView)
        reloadIITC()
    }

    func configureNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.bootFinished), name: JSNotificationBootFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.setIITCProgress(_:)), name: JSNotificationProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(MainViewController.sharedAction(_:)), name:JSNotificationSharedAction, object:nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "SwitchToPanel"), object: nil, queue: OperationQueue.main) {
            (notification) in
            let panel = (notification as NSNotification).userInfo!["Panel"] as! String
            self.switchToPanel(panel)
        }
        NotificationCenter.default.addObserver(forName: JSNotificationPermalinkChanged, object: nil, queue: OperationQueue.main) {
            (notification) in
            if let permalink = notification.userInfo?["data"] as? String {
                self.permalink = permalink
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        configureWebView()
        configureNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey:Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            let progress: Double = self.webView.estimatedProgress
            if progress >= 0.8 {
                if let host = self.webView.url?.host {
                    if host.contains("ingress") && self.loadIITCNeeded {
                        self.loadScripts()
                    }
                }
            }
            self.webProgressView.setProgress(Float(progress), animated: true)
            if progress == 1.0 {
                UIView.animate(withDuration: 1, animations: {
                    () -> Void in
                    self.webProgressView.alpha = 0
                }, completion: { result in
                    self.webProgressView.progress = 0
                }) 
            } else {
                self.webProgressView.alpha = 1
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: {
            () -> Void in
        })
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (action: UIAlertAction) -> Void in
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
            (action: UIAlertAction) -> Void in
            let input = alertController.textFields!.first!.text!
            completionHandler(input)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler(nil)
        }))
        self.present(alertController, animated: true, completion: nil)
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

    @IBAction func locationButtonPressed(_ aa: AnyObject) {
        let prefPersistentZoom = userDefaults.bool(forKey: "pref_persistent_zoom")
        if prefPersistentZoom {
            self.webView.evaluateJavaScript("window.map.locate({setView : true, maxZoom : map.getZoom()})")
        } else {
            self.webView.evaluateJavaScript("window.map.locate({setView : true})")
        }

    }

    @IBAction func settingsButtonPressed(_ sender: AnyObject) {
        let vc = SettingsViewController(style: .grouped)
        vc.neverShowPrivacySettings = true
        vc.showDoneButton = false
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func reloadButtonPressed(_ aa: AnyObject) {
        NotificationCenter.default.post(name:JSNotificationReloadRequired, object:nil)
    }

    @IBAction func linkButtonPressed(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Input intel URL", message: nil, preferredStyle: .alert)
        alert.addTextField {
            textField in
            textField.text = self.permalink
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
            let urlString = alert.textFields![0].text ?? ""
            if urlString == self.permalink {
                return
            }
            if let urlComponent = URLComponents(string: urlString) , urlComponent.host == "www.ingress.com" {
                self.webView.load(URLRequest(url: urlComponent.url!))
                self.loadIITCNeeded = true
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)

    }
    
    func bootFinished() {
        getLayers()
        self.webView.evaluateJavaScript("if(urlPortalLL[0] != undefined) window.selectPortalByLatLng(urlPortalLL[0],urlPortalLL[1]);")
    }

    var currentPanelID = "map"
    var backPanel = [String]()
    var backButtonPressed = false
    func setCurrentPanel(_ notification: Notification) {
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
        self.currentPanelID = panel;
    }

    func switchToPanel(_ pane: String) {
        self.webView.evaluateJavaScript(String(format: "window.show('%@')", pane))
    }

    func reloadIITC() {
        self.loadIITCNeeded = true
        if userDefaults.bool(forKey: "pref_force_desktop") {
            self.webView.load(URLRequest(url: URL(string: "https://www.ingress.com/intel?vp=f")!))
        } else {
            self.webView.load(URLRequest(url: URL(string: "https://www.ingress.com/intel")!))

        }
    }

    func setIITCProgress(_ notification: Notification) {
        if let progress = (notification as NSNotification).userInfo?["data"] as? Double {
            if progress != -1 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
    }

    func getLayers() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        print(#function)
//        print(navigationAction.request.mainDocumentURL)
        if let urlString = navigationAction.request.mainDocumentURL?.absoluteString {
            if urlString.contains("accounts.google"){
                self.loadIITCNeeded = true
            }
        }
        decisionHandler(.allow)
    }
    
    
    func sharedAction(_ notification:Notification) {
        let activityItem = (notification as NSNotification).userInfo!["data"] as! [AnyObject]
        let activityViewController = UIActivityViewController(activityItems: activityItem, applicationActivities: [OpenInMapActivity()])
        activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList]
        if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
            activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItems?.first
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "webview") as! UINavigationController
        let vc1 = vc.viewControllers[0] as! WebViewController
        vc1.configuration = configuration
        self.navigationController?.present(vc, animated: true, completion: nil)
        vc1.loadViewIfNeeded()
        return vc1.webView
    }
    
}

