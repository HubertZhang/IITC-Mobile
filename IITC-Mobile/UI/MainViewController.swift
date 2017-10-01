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
import WBWebViewConsole

class MainViewController: UIViewController {

    @available(iOS 11.0, *)
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    var webView: IITCWebView!
    var enableDebug: Bool = false
    var loadIITCNeeded = true
    var layersController: LayersController = LayersController.sharedInstance

    var location = IITCLocation()

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    var permalink: String = ""
    var currentPanelID = "map"
    var backPanel = [String]()
    var backButtonPressed = false

    var debugButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!

    @IBOutlet weak var webProgressView: UIProgressView!

    func syncCookie() {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        let cookieDirPath = containerPath.appendingPathComponent("Library/Cookies", isDirectory: true)
        let bakCookiePath = cookieDirPath.appendingPathComponent("Cookies.binarycookies", isDirectory: false)
        if FileManager.default.fileExists(atPath: bakCookiePath.path) {
            do {
                try FileManager.default.removeItem(atPath: bakCookiePath.path)
            } catch let error {
                debugPrint("error occurred, here are the details:\n \(error)")
            }
        } else {
            try? FileManager.default.createDirectory(at: cookieDirPath, withIntermediateDirectories: true, attributes: nil)
        }

        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
        let oriCookiePath = libraryPath.appendingPathComponent("Cookies/Cookies.binarycookies", isDirectory: false)
        try? FileManager.default.copyItem(at: oriCookiePath, to: bakCookiePath)
    }

    func configureWebView() {
        if enableDebug {
            self.webView = IITC1WebView(frame: CGRect.zero)
        } else {
            self.webView = IITCWebView(frame: CGRect.zero)
        }
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.view.addSubview(self.webView)

        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint.init(item: self.topLayoutGuide, attribute: .bottom, relatedBy: .equal, toItem: self.webView, attribute: .top, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.webView, attribute: .bottom, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .leading, relatedBy: .equal, toItem: self.webView, attribute: .leading, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint.init(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: self.webView, attribute: .trailing, multiplier: 1.0, constant: 0))
        NSLayoutConstraint.activate(constraints)

        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.view.bringSubview(toFront: webProgressView)
    }

    func configureNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.bootFinished), name: JSNotificationBootFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.setIITCProgress(_:)), name: JSNotificationProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.sharedAction(_:)), name: JSNotificationSharedAction, object: nil)
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SwitchToPanel"), object: nil, queue: OperationQueue.main) {
            (notification) in
            guard let panel = notification.userInfo?["Panel"] as? String else {
                return
            }
            self.switchToPanel(panel)
        }
        NotificationCenter.default.addObserver(forName: JSNotificationPermalinkChanged, object: nil, queue: OperationQueue.main) {
            (notification) in
            if let permalink = notification.userInfo?["data"] as? String {
                self.permalink = permalink
            }
        }
    }

    func configureRightButtons() {
        var buttons = [UIBarButtonItem]()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        settingsButton.setImage(#imageLiteral(resourceName:"ic_settings"), for: .normal)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: settingsButton))

        let locationButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        locationButton.setImage(#imageLiteral(resourceName:"ic_my_location"), for: .normal)
        locationButton.addTarget(self, action: #selector(locationButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: locationButton))

        let reloadButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        reloadButton.setImage(#imageLiteral(resourceName:"ic_refresh"), for: .normal)
        reloadButton.addTarget(self, action: #selector(reloadButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: reloadButton))

        let linkButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        linkButton.setImage(#imageLiteral(resourceName:"ic_link"), for: .normal)
        linkButton.addTarget(self, action: #selector(linkButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: linkButton))

        self.navigationItem.setRightBarButtonItems(buttons, animated: true)
    }

    func configureDebugButton() {
        debugButton = UIBarButtonItem(title: ">_", style: .plain, target: self, action: #selector(debugButtonPressed(_:)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        if NSUbiquitousKeyValueStore.default.longLong(forKey: ConsoleStateKey) != 0 {
            if userDefaults.bool(forKey: "pref_console") {
                enableDebug = true
            }
        }
#if arch(i386) || arch(x86_64)
        enableDebug = true
#endif
        configureDebugButton()
        configureRightButtons()
        configureWebView()
        configureNotification()

        reloadIITC()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if enableDebug {
            if !self.webView.isKind(of: IITC1WebView.self) {
                let alert = UIAlertController(title: "Console not loaded", message: "You have enabled Debug Console but it did not load. Please restart IITC to load Debug Console.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            guard var buttons = self.navigationItem.rightBarButtonItems else {
                return
            }
            if buttons.last != self.debugButton {
                buttons.append(self.debugButton)
                self.navigationItem.rightBarButtonItems = buttons
            }
        } else {
            guard var buttons = self.navigationItem.rightBarButtonItems else {
                return
            }
            if buttons.last == self.debugButton {
                _ = buttons.popLast()
                self.navigationItem.rightBarButtonItems = buttons
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            let progress: Double = self.webView.estimatedProgress
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
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func reloadIITC() {
        self.loadIITCNeeded = true
        let userAgent = userDefaults.string(forKey: "pref_useragent")
        if userAgent != "" {
            self.webView.customUserAgent = userAgent
        }
        if userDefaults.bool(forKey: "pref_force_desktop") {
            self.webView.load(URLRequest(url: URL(string: "https://www.ingress.com/intel?vp=f")!))
        } else {
            self.webView.load(URLRequest(url: URL(string: "https://www.ingress.com/intel")!))

        }
    }

    func switchToPanel(_ pane: String) {
        self.webView.evaluateJavaScript(String(format: "window.show('%@')", pane))
    }

    // MARK: Toolbar Buttons
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
        vc.title = "Settings"
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func reloadButtonPressed(_ aa: AnyObject) {
        NotificationCenter.default.post(name: JSNotificationReloadRequired, object: nil)
    }

    @IBAction func debugButtonPressed(_ sender: Any) {
        if enableDebug {
            let vc = WBWebDebugConsoleViewController(console: (self.webView as! IITC1WebView).console!)!
            let vc1 = UINavigationController.init(rootViewController: vc)
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: vc, action: #selector(WBWebDebugConsoleViewController.dismissSelf))
            vc1.modalPresentationStyle = UIModalPresentationStyle.popover
            vc1.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(vc1, animated: true, completion: nil)
        } else {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "purchase") else {
                return
            }
            vc.modalPresentationStyle = UIModalPresentationStyle.popover
            vc.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(vc, animated: true, completion: nil)
        }
    }

    @IBAction func linkButtonPressed(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Input intel URL", message: nil, preferredStyle: .alert)
        alert.addTextField {
            textField in
            textField.text = self.permalink
            textField.keyboardType = .URL
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            let urlString = alert.textFields![0].text ?? ""
            if urlString == self.permalink {
                return
            }
            if let urlComponent = URLComponents(string: urlString), urlComponent.host == "www.ingress.com" {
                self.webView.load(URLRequest(url: urlComponent.url!))
                self.loadIITCNeeded = true
            }
            if urlString == "https://ops.irde.net/iitc" {
                self.webView.load(URLRequest(url: URL(string: urlString)!))
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)

    }

    // MARK: IITC Callbacks
    @objc func bootFinished() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
        self.webView.evaluateJavaScript("if(urlPortalLL[0] != undefined) window.selectPortalByLatLng(urlPortalLL[0],urlPortalLL[1]);")
    }

    @objc func setCurrentPanel(_ notification: Notification) {
        guard let panel = notification.userInfo?["paneID"] as? String else {
            return
        }

        if (panel == self.currentPanelID) {
            return
        }

        // map pane is top-lvl. clear stack.
        if (panel == "map") {
            self.backPanel.removeAll()
            self.backButton.isEnabled = false
        }
        // don't push current pane to backstack if this method was called via back button
        else if (!self.backButtonPressed) {
            self.backPanel.append(self.currentPanelID)
            self.backButton.isEnabled = true
        }

        self.backButtonPressed = false
        self.currentPanelID = panel
    }

    @objc func setIITCProgress(_ notification: Notification) {
        if let progress = notification.userInfo?["data"] as? NSNumber {
            if progress.doubleValue == 1 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
    }

    @objc func sharedAction(_ notification: Notification) {
        let activityItem = notification.userInfo?["data"] as? [Any] ?? [Any]()
        let activityViewController = UIActivityViewController(activityItems: activityItem, applicationActivities: [OpenInMapActivity()])
        activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList]
        if activityViewController.responds(to: #selector(getter:UIViewController.popoverPresentationController)) {
            activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItems?.first
        }
        self.present(activityViewController, animated: true, completion: nil)
    }

    // MARK: Segue Handler
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "layerChooser" {
            self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
        }
    }

    func topViewController() -> UIViewController? {
        if self.isBeingPresented {
            return self
        } else {
            var v = UIApplication.shared.keyWindow?.rootViewController
            while v?.presentedViewController != nil {
                v = v?.presentedViewController
            }
            return v
        }
    }
}

extension MainViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
            _ -> Void in
            completionHandler()
        }))
        self.topViewController()?.present(alertController, animated: true)
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
        self.topViewController()?.present(alertController, animated: true, completion: nil)
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
        self.topViewController()?.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let vc = self.storyboard!.instantiateViewController(withIdentifier: "webview") as? UINavigationController else {
            return nil
        }
        guard let vc1 = vc.viewControllers[0] as? WebViewController else {
            return nil
        }
        vc1.configuration = configuration
        self.navigationController?.present(vc, animated: true, completion: nil)
        vc1.loadViewIfNeeded()
        let userAgent = userDefaults.string(forKey: "pref_useragent")
        if userAgent != "" {
            vc1.webView.customUserAgent = userAgent
        }
        return vc1.webView
    }
}

extension MainViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        print(navigationAction.request)
//        print(navigationAction.request.mainDocumentURL)
        if enableDebug {
            let r = (self.webView as! IITC1WebView).jsBridge.handleWebViewRequest(navigationAction.request)
            if r {
                decisionHandler(.cancel)
                return
            }
        }
//        print("Allowed")
        if let urlString = navigationAction.request.mainDocumentURL?.absoluteString {
            if urlString.contains("google.com") || urlString.contains("ops.irde.net") {
//                print("Allowed1")
                if enableDebug {
                    (self.webView as! IITC1WebView).console.clearMessages()
                    (self.webView as! IITC1WebView).wb_removeAllUserScripts()
                } else {
                    self.webView.configuration.userContentController.removeAllUserScripts()
                }
                self.backPanel.removeAll()
                self.backButton.isEnabled = false
                self.loadIITCNeeded = true
            } else if urlString.contains("ingress.com/intel") && self.loadIITCNeeded {
//                print("Allowed2")
                if enableDebug {
                    (self.webView as! IITC1WebView).console.clearMessages()
                    (self.webView as! IITC1WebView).wb_removeAllUserScripts()
                } else {
                    self.webView.configuration.userContentController.removeAllUserScripts()
                }
                var scripts = ScriptsManager.sharedInstance.getLoadedScripts()
                let currentMode = IITCLocationMode(rawValue: userDefaults.integer(forKey: "pref_user_location_mode"))!
                if currentMode != .notShow {
                    scripts.append(ScriptsManager.sharedInstance.positionScript)
                }
                for script in scripts {
                    self.webView.configuration.userContentController.addUserScript(WKUserScript.init(source: script.fileContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
                }
                self.loadIITCNeeded = false
                syncCookie()
            }
        }
        decisionHandler(.allow)
    }

}

extension WBWebDebugConsoleViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
