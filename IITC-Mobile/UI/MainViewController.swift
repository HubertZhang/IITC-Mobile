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
import WebViewConsole
import WebViewConsoleView
import RxSwift

class MainViewController: UIViewController {

    @available(iOS 11.0, *)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    var webView: IITCWebViewController!

    var layersController: LayersController = LayersController.sharedInstance

    var location = IITCLocation()

    var userDefaults = sharedUserDefaults

    var debugConsoleEnabled: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return InAppPurchaseManager.default.consolePurchased && userDefaults.bool(forKey: "pref_console")
        #endif
    }
    var debugButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!

    let disposeBag = DisposeBag()

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

    func configureNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.setIITCProgress(_:)), name: JSNotificationProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.sharedAction(_:)), name: JSNotificationSharedAction, object: nil)
        NotificationCenter.default.addObserver(forName: JSNotificationBootFinished, object: nil, queue: .main) {
            [weak self] (_) in
            self?.syncCookie()
        }
    }

    func configureRightButtons() {
        var buttons = [UIBarButtonItem]()
        let settingsButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        settingsButton.setImage(#imageLiteral(resourceName: "ic_settings"), for: .normal)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: settingsButton))

        let locationButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        locationButton.setImage(#imageLiteral(resourceName: "ic_my_location"), for: .normal)
        locationButton.addTarget(self, action: #selector(locationButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: locationButton))

        let reloadButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        reloadButton.setImage(#imageLiteral(resourceName: "ic_refresh"), for: .normal)
        reloadButton.addTarget(self, action: #selector(reloadButtonPressed(_:)), for: .touchUpInside)
        buttons.append(UIBarButtonItem(customView: reloadButton))

        let linkButton = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 24))
        linkButton.setImage(#imageLiteral(resourceName: "ic_link"), for: .normal)
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

        configureDebugButton()
        configureRightButtons()
        configureNotification()

        self.webView.canGoBack.bind(to: self.backButton.rx.isEnabled).disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.webView.setConsole(enabled: self.debugConsoleEnabled)

        if self.debugConsoleEnabled {
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

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Toolbar Buttons
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        self.webView.goBackPanel()
    }

    @IBAction func locationButtonPressed(_ aa: AnyObject) {
        self.webView.locate()
    }

    @IBAction func settingsButtonPressed(_ sender: AnyObject) {
        let vc = SettingsViewController(style: .grouped)
        vc.showDoneButton = false
        vc.title = "Settings"
        vc.neverShowPrivacySettings = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func reloadButtonPressed(_ aa: AnyObject) {
        NotificationCenter.default.post(name: JSNotificationReloadRequired, object: nil)
    }

    @IBAction func debugButtonPressed(_ sender: Any) {
        if self.debugConsoleEnabled {
            let vc = ConsoleViewController.init(with: self.webView.console, notificationName: WebViewConsoleMessageUpdated)
            let vc1 = UINavigationController.init(rootViewController: vc)
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: vc, action: #selector(ConsoleViewController.dismissSelf))
            vc1.modalPresentationStyle = UIModalPresentationStyle.popover
            vc1.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(vc1, animated: true, completion: nil)
        }
    }

    @IBAction func linkButtonPressed(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Input intel URL", message: nil, preferredStyle: .alert)
        alert.addTextField {
            textField in
            textField.text = self.webView.permalink
            textField.keyboardType = .URL
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            let urlString = alert.textFields![0].text ?? ""
            if urlString == self.webView.permalink {
                return
            }
            if let urlComponent = URLComponents(string: urlString) {
                if urlComponent.host == "www.ingress.com" || urlComponent.host == "intel.ingress.com" {
                    self.webView.loadIITCNeeded = true
                }
                self.webView.load(url: urlComponent.url!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)

    }

    // MARK: IITC Callbacks

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
        let activityViewController = UIActivityViewController(activityItems: activityItem, applicationActivities: [OpenInMapActivity(), CopyPortalLinkActivity(), OpenInGMapActivity(), OpenInAmapActivity(), OpenInBaiduMapActivity()])
        activityViewController.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
        if activityViewController.responds(to: #selector(getter:UIViewController.popoverPresentationController)) {
            activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItems?.first
        }
        self.present(activityViewController, animated: true, completion: nil)
    }

    // MARK: Segue Handler
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "layerChooser" {
            self.webView.needUpdateLayer()
        } else if segue.identifier == "embedIITC" {
            self.webView = (segue.destination as! IITCWebViewController)
            self.webView.webViewUIDelegate = self
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
        configuration.userContentController.removeAllUserScripts()
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
