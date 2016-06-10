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

class ActionViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: IITCWebView!
    
    var location = IITCLocation()
    
    var layersController: LayersController = LayersController.sharedInstance
    
    var url:NSURL = NSURL(string:"https://www.ingress.com/intel")!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    @IBOutlet weak var webProgressView: UIProgressView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var loadIITCNeeded = true
    
    func loadScripts() {
        self.webView.loadScripts(ScriptsManager.sharedInstance.getLoadedScripts())
        loadIITCNeeded = false
    }
    
    func configureWebView() {
        self.webView = IITCWebView(frame: CGRectZero)
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.UIDelegate = self
        self.view.addSubview(self.webView);
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint.init(item: self.navigationBar, attribute: .Bottom, relatedBy: .Equal, toItem: self.webView, attribute: .Top, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.bottomLayoutGuide, attribute: .Top, relatedBy: .Equal, toItem: self.webView, attribute: .Bottom, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: self.webView, attribute: .Leading, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.webView, attribute: .Trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraints(constraints)
        
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        self.view.bringSubviewToFront(webProgressView)
    }
    
    func configureNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(bootFinished), name: JSNotificationBootFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(sharedAction(_:)), name:JSNotificationSharedAction, object:nil)
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
        self.loadIITCNeeded = true
        var founded = false
        for item: AnyObject in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: AnyObject in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    founded = true
                    itemProvider.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil, completionHandler: { (url, error) in
                        let wrappedURL = url as! NSURL
                        print(wrappedURL)
                        if wrappedURL.host == "www.ingress.com" {
                            self.url = wrappedURL
                            
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                self.webView.loadRequest(NSURLRequest(URL: wrappedURL))
                            }
                        } else {
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                self.webProgressView.hidden = true
                                self.webView.loadHTMLString("Link not supported", baseURL: nil)
                            }
                        }
                    })
                    break
                }
            }
        }
        if !founded {
            self.webProgressView.hidden = true
            self.webView.loadHTMLString("Link not supported", baseURL: nil)
        }
    }
    
    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
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
    
    @IBAction func reloadButtonPressed(aa: AnyObject) {
        reloadIITC()
    }
    
    @IBAction func openInIITC(sender: AnyObject) {
        guard let components = NSURLComponents(URL: self.url, resolvingAgainstBaseURL: true) else {
            return
        }
        components.scheme = "iitc"
        components.host = ""
        print(components.URL)
        self.extensionContext?.openURL(components.URL!, completionHandler: {
            result in
            self.done()
            
        })
    }
    
    func bootFinished() {
        getLayers()
        self.webView.evaluateJavaScript("window.selectPortalByLatLng(urlPortalLL[0],urlPortalLL[1]);")
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
        self.webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func getLayers() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
    }
    
    func sharedAction(notification:NSNotification) {
        self.webView.evaluateJavaScript("window.dialog({text:\"Not supported in Action\"})")
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
}
