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
    
    var userDefaults = NSUserDefaults(suiteName: ContainerIdentifier)!
    
    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var webProgressView: UIProgressView!


    var loadIITCNeeded = true

    func loadScripts() {
        self.webView.loadScripts(ScriptsManager.sharedInstance.getLoadedScripts())
        loadIITCNeeded = false
        syncCookie()
    }
    
    func syncCookie() {
        let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(ContainerIdentifier)!
        let cookieDirPath = containerPath.URLByAppendingPathComponent("Library/Cookies", isDirectory: true)
        let bakCookiePath = cookieDirPath.URLByAppendingPathComponent("Cookies.binarycookies", isDirectory: false)
        if NSFileManager.defaultManager().fileExistsAtPath(bakCookiePath.path!) {
            return
        }
        
        let libraryPath = NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).last!
        let oriCookiePath = libraryPath.URLByAppendingPathComponent("Cookies/Cookies.binarycookies", isDirectory: false)
        if !NSFileManager.defaultManager().fileExistsAtPath(oriCookiePath.path!) {
            return
        }
        try? NSFileManager.defaultManager().createDirectoryAtURL(cookieDirPath, withIntermediateDirectories: true, attributes: nil)
        try? NSFileManager.defaultManager().copyItemAtURL(oriCookiePath, toURL: bakCookiePath)
    }

    func configureWebView() {
        self.webView = IITCWebView(frame: CGRectZero)

        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.UIDelegate = self
        self.view.addSubview(self.webView);

        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint.init(item: self.topLayoutGuide, attribute: .Bottom, relatedBy: .Equal, toItem: self.webView, attribute: .Top, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.bottomLayoutGuide, attribute: .Top, relatedBy: .Equal, toItem: self.webView, attribute: .Bottom, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: self.webView, attribute: .Leading, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.webView, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraints(constraints)

        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        self.view.bringSubviewToFront(webProgressView)
        reloadIITC()
    }

    func configureNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.bootFinished), name: JSNotificationBootFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.setIITCProgress(_:)), name: JSNotificationProgressChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(MainViewController.sharedAction(_:)), name:JSNotificationSharedAction, object:nil)
        NSNotificationCenter.defaultCenter().addObserverForName("SwitchToPanel", object: nil, queue: NSOperationQueue.mainQueue()) {
            (notification) in
            let panel = notification.userInfo!["Panel"] as! String
            self.switchToPanel(panel)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        configureWebView()
        configureNotification()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String:AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "estimatedProgress") {
            let progress: Double = self.webView.estimatedProgress
            if progress >= 0.8 {
                if let host = self.webView.URL?.host {
                    if host.containsString("ingress") && self.loadIITCNeeded {
                        self.loadScripts()
                    }
                }
            }
            self.webProgressView.setProgress(Float(progress), animated: true)
            if progress == 1.0 {
                UIView.animateWithDuration(1, animations: {
                    () -> Void in
                    self.webProgressView.alpha = 0
                }) { result in
                    self.webProgressView.progress = 0
                }
            } else {
                self.webProgressView.alpha = 1
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler()
        }))
        self.presentViewController(alertController, animated: true, completion: {
            () -> Void in
        })
    }

    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        let alertController = UIAlertController(title: prompt, message: webView.URL!.host, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler({
            (textField: UITextField) -> Void in
            textField.text = defaultText
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            let input = alertController.textFields!.first!.text!
            completionHandler(input)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler(nil)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @IBAction func backButtonPressed(sender: AnyObject) {
        if !self.backPanel.isEmpty {
            let panel = self.backPanel.removeLast()

            self.switchToPanel(panel)
            self.backButtonPressed = true
        }
        if self.backPanel.isEmpty {
            self.backButton.enabled = false
        }
    }

    @IBAction func locationButtonPressed(aa: AnyObject) {
        let prefPersistentZoom = userDefaults.boolForKey("pref_persistent_zoom")
        if prefPersistentZoom {
            self.webView.evaluateJavaScript("window.map.locate({setView : true, maxZoom : map.getZoom()})")
        } else {
            self.webView.evaluateJavaScript("window.map.locate({setView : true})")
        }

    }

    @IBAction func settingsButtonPressed(sender: AnyObject) {
        let vc = SettingsViewController(style: .Grouped)
        vc.neverShowPrivacySettings = true
        vc.showDoneButton = false
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func reloadButtonPressed(aa: AnyObject) {
        reloadIITC()
    }

    func bootFinished() {
        getLayers()
    }

    var currentPanelID = "map"
    var backPanel = [String]()
    var backButtonPressed = false
    func setCurrentPanel(notification: NSNotification) {
        guard let panel = notification.userInfo?["paneID"] as? String else {
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
            self.backButton.enabled = true
        }

        self.backButtonPressed = false
        self.currentPanelID = panel;
    }

    func switchToPanel(pane: String) {
        self.webView.evaluateJavaScript(String(format: "window.show('%@')", pane))
    }

    func reloadIITC() {
        self.loadIITCNeeded = true
        if userDefaults.boolForKey("pref_force_desktop") {
            self.webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://www.ingress.com/intel?vp=f")!))
        } else {
            self.webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://www.ingress.com/intel")!))

        }
    }

    func setIITCProgress(notification: NSNotification) {
        if let progress = notification.userInfo?["data"] as? Double {
            if progress != -1 {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            } else {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            }
        }
    }

    func getLayers() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
//        print(#function)
//        print(navigationAction.request.mainDocumentURL)
        if let urlString = navigationAction.request.mainDocumentURL?.absoluteString {
            if urlString.containsString("accounts.google"){
                self.loadIITCNeeded = true
            }
        }
        decisionHandler(.Allow)
    }
    
    
    func sharedAction(notification:NSNotification) {
        let activityItem = notification.userInfo!["data"] as! [AnyObject]
        let activityViewController = UIActivityViewController(activityItems: activityItem, applicationActivities: [OpenInMapActivity()])
        activityViewController.excludedActivityTypes = [UIActivityTypeAddToReadingList]
        if activityViewController.respondsToSelector(Selector("popoverPresentationController")) {
            activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItems?.first
        }
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
}

