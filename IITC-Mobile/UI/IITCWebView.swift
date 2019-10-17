//
//  IITC1WebView.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/6/24.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import WebKit
import BaseFramework
import WBWebViewConsole

class IITCWebView: WKWebView, WBWebView {
    var wb_userScripts: [Any] {
        return self.configuration.userContentController.userScripts
    }

    private(set) var consoleEnabled: Bool = false

    var jsBridge: WBWebViewJSBridge!
    var console: WBWebViewConsole!

    public init(frame: CGRect) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        handler.initHandlers(for: &configuration.userContentController)
        super.init(frame: frame, configuration: configuration)
        self.isOpaque = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self.wb_evaluateJavaScript(JS, completionHandler: nil)
        }
        #if arch(i386) || arch(x86_64)
            enableConsole()
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enableConsole() {
        if !self.consoleEnabled {
            self.consoleEnabled = true
            jsBridge = WBWebViewJSBridge(webView: self)
            jsBridge.interfaceName = "WKWebViewBridge"
            jsBridge.readyEventName = "WKWebViewBridgeReady"
            jsBridge.invokeScheme = "wkwebview-bridge://invoke"
            console = WBWebViewConsole(webView: self)
        }
    }

    func wb_add(_ userScript: WBWebViewUserScript!) {
        if userScript.scriptInjectionTime == .atDocumentEnd {
            self.configuration.userContentController.addUserScript(WKUserScript(source: userScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: userScript.isForMainFrameOnly))
        } else {
            self.configuration.userContentController.addUserScript(WKUserScript(source: userScript.source, injectionTime: .atDocumentStart, forMainFrameOnly: userScript.isForMainFrameOnly))
        }
    }

    func wb_removeAllUserScripts() {
        if !consoleEnabled {
            self.configuration.userContentController.removeAllUserScripts()
            return
        }
        var wbScript: WKUserScript?
        var wbConsoleScript: WKUserScript?
        for script in self.configuration.userContentController.userScripts {
            if script.source.contains("Copyright (c) 2014-present, Weibo, Corp.") {
                wbScript = script
            }
            if script.source.contains("__WeiboDebugConsole") {
                wbConsoleScript = script
            }
        }
        self.configuration.userContentController.removeAllUserScripts()
        if wbScript != nil {
            self.configuration.userContentController.addUserScript(wbScript!)
        }
        if wbConsoleScript != nil {
            self.configuration.userContentController.addUserScript(wbConsoleScript!)
        }
    }

    func wb_evaluateJavaScript(_ javaScriptString: String, completionHandler: ((String?, Error?) -> Void)!) {
        self.evaluateJavaScript(javaScriptString) {
            (response, error) -> Void in
            if completionHandler == nil {
                return
            }
            completionHandler(response as? String, error)
        }
    }

}
