//
//  IITCWebView.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/2/16.
//  Copyright © 2016年 IITC. All rights reserved.
//

import Foundation
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func evaluateJavaScript(javaScriptString: String) {
        self.evaluateJavaScript(javaScriptString) {
            (response, error) -> Void in
            
        }
    }
    
    func loadScripts(filePaths:[NSURL]) {
        for file in filePaths {
            let js = String(fileContent:file, encoding: NSUTF8StringEncoding)
            self.evaluateJavaScript(js) {
                (response, error) -> Void in
                
            }
        }
    }
}