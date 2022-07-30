//
//  IITCWebViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/12/15.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit
import WebKit
import RxCocoa
import WebViewConsole

var initialQueryItems: [URLQueryItem]?

public func setInitialQueryItems(_ items: [URLQueryItem]?) {
    initialQueryItems = items
}

public class IITCWebViewController: UIViewController {
    @IBOutlet weak var webProgressView: UIProgressView!
    var webView: IITCWebView!
    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    public var console: WebViewConsole {
        return webView.console
    }

    public var layerController = LayersController.sharedInstance

    public weak var webViewUIDelegate: WKUIDelegate?

    public var loadIITCNeeded = true

    private var observationProgress: NSKeyValueObservation?

    func configureWebView() {
        self.webView = IITCWebView(frame: CGRect.zero)
        if #available(iOS 11.0, *) {
            self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.configuration.selectionGranularity = .dynamic
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self.webViewUIDelegate
        self.view.addSubview(self.webView)

        NSLayoutConstraint.activate([
            self.view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: self.webView.topAnchor),
            self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
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

    func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadIITC), name: JSNotificationReloadRequired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bootFinished), name: JSNotificationBootFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setCurrentPanel(_:)), name: JSNotificationPaneChanged, object: nil)
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SwitchToPanel"), object: nil, queue: OperationQueue.main) {
            [weak self] (notification) in
            guard let panel = notification.userInfo?["Panel"] as? String else {
                return
            }
            self?.switchToPanel(panel)
        }
        NotificationCenter.default.addObserver(forName: JSNotificationPermalinkChanged, object: nil, queue: OperationQueue.main) {
            [weak self] (notification) in
            if let permalink = notification.userInfo?["data"] as? String {
                self?.permalink = permalink
            }
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureWebView()
        configureNotifications()

        reloadIITC()
    }

    deinit {
        self.observationProgress = nil
    }

    public func setConsole(enabled: Bool) {
        if enabled {
            self.webView.enableConsole()
        } else {
            self.webView.disableConsole()
        }
    }

    // MARK: panel stack control
    var currentPanelID = "map"
    var backPanel = [String]()
    var backButtonPressed = false
    public private(set) var canGoBack = BehaviorRelay<Bool>(value: false)

    public func switchToPanel(_ pane: String) {
        self.webView.evaluateJavaScript(String(format: "window.show('%@')", pane))
    }

    public func goBackPanel() {
        if !self.backPanel.isEmpty {
            let panel = self.backPanel.removeLast()

            self.switchToPanel(panel)
            self.backButtonPressed = true
        }
        if self.backPanel.isEmpty {
            canGoBack.accept(false)
        }
    }

    // MARK: IITC Callbacks
    public var permalink: String = ""
    @objc public func reloadIITC() {
        self.loadIITCNeeded = true
        var userAgent = userDefaults.string(forKey: "pref_useragent") ?? PredefinedUserAgents[0].1
        if userAgent == "" {
            userAgent = PredefinedUserAgents[0].1
        }
        self.webView.customUserAgent = userAgent
        var intelURL = URLComponents(string: "https://intel.ingress.com/intel")!
        intelURL.queryItems = []
        if userDefaults.bool(forKey: "pref_force_desktop") {
            intelURL.queryItems!.append(URLQueryItem(name: "vp", value: "f"))
        }

        if initialQueryItems != nil {
            intelURL.queryItems!.append(contentsOf: initialQueryItems!)
            initialQueryItems = nil
        }

        self.webView.load(URLRequest(url: intelURL.url!))
    }

    @objc public func bootFinished() {
        self.webView.evaluateJavaScript("if(urlPortalLL[0] != undefined) window.selectPortalByLatLng(urlPortalLL[0],urlPortalLL[1]);")
        needUpdateLayer()
    }

    @objc public func setCurrentPanel(_ notification: Notification) {
        guard let panel = notification.userInfo?["paneID"] as? String else {
            return
        }

        if panel == self.currentPanelID {
            return
        }

        // map pane is top-lvl. clear stack.
        if panel == "map" {
            self.backPanel.removeAll()
            canGoBack.accept(false)
        }
        // don't push current pane to backstack if this method was called via back button
        else if !self.backButtonPressed {
            self.backPanel.append(self.currentPanelID)
            canGoBack.accept(true)
        }

        self.backButtonPressed = false
        self.currentPanelID = panel
    }
}

extension IITCWebViewController {
    public func locate() {
        let prefPersistentZoom = userDefaults.bool(forKey: "pref_persistent_zoom")
        if prefPersistentZoom {
            self.webView.evaluateJavaScript("window.map.locate({setView : true, maxZoom : map.getZoom()})")
        } else {
            self.webView.evaluateJavaScript("window.map.locate({setView : true})")
        }
    }

    public func load(url: URL) {
        self.webView.load(URLRequest(url: url))
    }

    public func load(urlString: String) {
        self.webView.load(URLRequest(url: URL(string: urlString)!))
    }

    public func load(htmlString: String) {
        self.webView.loadHTMLString(htmlString, baseURL: nil)
    }

    public func needUpdateLayer() {
        self.webView.evaluateJavaScript("window.layerChooser.getLayers()")
    }
}

extension IITCWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView || !(navigationAction.targetFrame?.isMainFrame ?? false) {
            decisionHandler(.allow)
            return
        }
        if let urlString = navigationAction.request.mainDocumentURL?.absoluteString, let host = URLComponents(string: urlString)?.host {
            if (host.contains("ingress.com/intel") || host.contains("intel.ingress.com")) && self.loadIITCNeeded {
                if self.webView.consoleEnabled {
                    self.webView.console.clearMessages()
                }
                self.layerController.reset()
                self.webView.removeAllUserScripts()
                var scripts = ScriptsManager.sharedInstance.getLoadedScripts()
                let currentMode = IITCLocationMode(rawValue: userDefaults.integer(forKey: "pref_user_location_mode"))!
                if currentMode != .notShow {
                    scripts.append(ScriptsManager.sharedInstance.positionScript)
                }
                for script in scripts {
                    self.webView.configuration.userContentController.addUserScript(WKUserScript.init(source: script.fileContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
                }
                self.loadIITCNeeded = false
            } else {
                if self.webView.consoleEnabled {
                    self.webView.console.clearMessages()
                }
                self.webView.removeAllUserScripts()
                self.backPanel.removeAll()
                self.loadIITCNeeded = true
            }
        }
        decisionHandler(.allow)
    }

}
