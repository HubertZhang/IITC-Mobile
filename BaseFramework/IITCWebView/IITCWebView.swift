//
//  IITC1WebView.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/6/24.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import WebKit
import WebViewConsole

class IITCWebView: WKWebView {
    private(set) var consoleEnabled: Bool = false

    var console: WebViewConsole!

    public init(frame: CGRect) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        handler.initHandlers(for: &configuration.userContentController)
        super.init(frame: frame, configuration: configuration)
        self.isOpaque = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            [weak self] (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self?.evaluateJavaScript(JS, completionHandler: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enableConsole() {
        if !self.consoleEnabled {
            self.consoleEnabled = true
            console = WebViewConsole(name: "iitc_console")
            self.console.setup(webView: self)
        }
    }

    func disableConsole() {
        if self.consoleEnabled {
            self.consoleEnabled = false
            self.configuration.userContentController.removeAllUserScripts()
            self.configuration.userContentController.removeScriptMessageHandler(forName: "iitc_console")
        }
    }

    func add(userScript: WKUserScript) {
        self.configuration.userContentController.addUserScript(userScript)
    }

    func removeAllUserScripts() {
        self.configuration.userContentController.removeAllUserScripts()

        if self.consoleEnabled {
            self.console.setupUserScript(to: self)
        }
    }
}
