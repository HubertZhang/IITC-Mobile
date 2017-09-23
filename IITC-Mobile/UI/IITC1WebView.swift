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

class IITC1WebView: IITCWebView, WBWebView {
    var wb_userScripts: [Any] {
        return self.configuration.userContentController.userScripts
    }


    var jsBridge: WBWebViewJSBridge!
    var console: WBWebViewConsole!


    public override init(frame: CGRect) {
        super.init(frame: frame)
        jsBridge = WBWebViewJSBridge(webView: self)
        jsBridge.interfaceName = "WKWebViewBridge"
        jsBridge.readyEventName = "WKWebViewBridgeReady"
        jsBridge.invokeScheme = "wkwebview-bridge://invoke"
        console = WBWebViewConsole(webView: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func wb_add(_ userScript: WBWebViewUserScript!) {
        if userScript.scriptInjectionTime == .atDocumentEnd {
            self.configuration.userContentController.addUserScript(WKUserScript(source: userScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: userScript.isForMainFrameOnly))
        } else {
            self.configuration.userContentController.addUserScript(WKUserScript(source: userScript.source, injectionTime: .atDocumentStart, forMainFrameOnly: userScript.isForMainFrameOnly))
        }
    }

    func wb_removeAllUserScripts() {
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

    func wb_evaluateJavaScript(_ javaScriptString: String!, completionHandler: ((String?, Error?) -> Void)!) {
        self.evaluateJavaScript(javaScriptString) {
            (response, error) -> Void in
            if completionHandler == nil {
                return
            }
            completionHandler(response as? String, error)
        }
    }

}
