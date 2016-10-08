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

class ActionViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, URLSessionDelegate, URLSessionDownloadDelegate {
    
    var webView: IITCWebView!
    
    var location = IITCLocation()
    
    var layersController: LayersController = LayersController.sharedInstance
    
    var url:URL = URL(string:"https://www.ingress.com/intel")!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    @IBOutlet weak var webProgressView: UIProgressView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var loadIITCNeeded = true

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.vuryleo.iitcmobile.background")
        config.sharedContainerIdentifier = ContainerIdentifier
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func loadScripts() {
        self.webView.loadScripts(ScriptsManager.sharedInstance.getLoadedScripts())
        loadIITCNeeded = false
    }
    
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
            return
        }
        try? FileManager.default.createDirectory(at: cookieDirPath, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.copyItem(at: bakCookiePath, to: cookiePath)
    }

    func handleJSFileURL(_ url: URL) {
        let alert = UIAlertController(title: "Save JS File to IITC?", message: "A JavaScript file detected. Would you like to save this file to IITC (as a Plugin)?\nURL:\(url.absoluteString)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
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
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView);
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint.init(item: self.navigationBar, attribute: .bottom, relatedBy: .equal, toItem: self.webView, attribute: .top, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.bottomLayoutGuide, attribute: .top, relatedBy: .equal, toItem: self.webView, attribute: .bottom, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .leading, relatedBy: .equal, toItem: self.webView, attribute: .leading, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: self.webView, attribute: .trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraints(constraints)
        
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.view.bringSubview(toFront: webProgressView)
    }
    
    func configureNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(bootFinished), name: JSNotificationBootFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(sharedAction(_:)), name:JSNotificationSharedAction, object:nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "SwitchToPanel"), object: nil, queue: OperationQueue.main) {
            (notification) in
            let panel = (notification as NSNotification).userInfo!["Panel"] as! String
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
        for item: Any in self.extensionContext!.inputItems {
            let inputItem = item as! NSExtensionItem
            for provider: Any in inputItem.attachments! {
                let itemProvider = provider as! NSItemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    founded = true
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: { (url, error) in
                        let wrappedURL = url as! URL
                        print(wrappedURL)
                        if wrappedURL.host == "www.ingress.com" {
                            self.url = wrappedURL
                            
                            OperationQueue.main.addOperation {
                                self.webView.load(URLRequest(url: wrappedURL))
                            }
                        } else if wrappedURL.pathExtension == "js" {
                            OperationQueue.main.addOperation {
                                self.webView.loadHTMLString("JSFile", baseURL: nil)
                                self.handleJSFileURL(wrappedURL)
                            }
                        } else {
                            OperationQueue.main.addOperation {
                                self.webProgressView.isHidden = true
                                self.webView.loadHTMLString("Link not supported", baseURL: nil)
                            }
                        }
                    })
                    break
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
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler()
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
    
    @IBAction func reloadButtonPressed(_ aa: AnyObject) {
        reloadIITC()
    }
    
    @IBAction func openInIITC(_ sender: AnyObject) {
        guard var components = URLComponents(url: self.url, resolvingAgainstBaseURL: true) else {
            return
        }
        components.scheme = "iitc"
        components.host = ""
        print(components.url)
        self.extensionContext?.open(components.url!, completionHandler: {
            result in
            self.done()
            
        })
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
        self.webView.load(URLRequest(url: url))
    }
    
    func getLayers() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
    }
    
    func sharedAction(_ notification:Notification) {
        self.webView.evaluateJavaScript("window.dialog({text:\"Not supported in Action\"})")
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
}
