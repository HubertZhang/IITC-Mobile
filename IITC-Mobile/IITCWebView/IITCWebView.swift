//
//  IITCWebView.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/2/16.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit

@objc class IITCWebView: WKWebView {
    
    init(frame: CGRect) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        configuration.userContentController.addScriptMessageHandler(handler, name: "ios")
        super.init(frame: frame, configuration: configuration)
        NSNotificationCenter.defaultCenter().addObserverForName("WebViewExecuteJS", object: nil, queue: nil) { (notification) -> Void in
            let JS = notification.userInfo!["JS"] as! String
            self.evaluateJavaScript(JS)
        }
    }
    
    init(withScripts scripts:[Script]) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        configuration.userContentController.addScriptMessageHandler(handler, name: "ios")
        for script in scripts {
            configuration.userContentController.addUserScript(WKUserScript(source: script.fileContent, injectionTime: .AtDocumentStart, forMainFrameOnly: true))
        }
        
        super.init(frame: CGRectZero, configuration: configuration)
        NSNotificationCenter.defaultCenter().addObserverForName("WebViewExecuteJS", object: nil, queue: nil) { (notification) -> Void in
            let JS = notification.userInfo!["JS"] as! String
            self.evaluateJavaScript(JS)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func evaluateJavaScript(javaScriptString: String) {
        self.evaluateJavaScript(javaScriptString) {
            (response, error) -> Void in
            
        }
    }
    
    func loadScripts(scripts:[Script]) {
        for script in scripts {
            self.evaluateJavaScript(script.fileContent) {
                (response, error) -> Void in
                
            }
        }
    }
}