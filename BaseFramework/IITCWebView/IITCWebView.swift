//
//  IITCWebView.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/2/16.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit

@objc open class IITCWebView: WKWebView {

    public init(frame: CGRect) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        configuration.userContentController.add(handler, name: "ios")
        super.init(frame: frame, configuration: configuration)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self.evaluateJavaScript(JS)
        }
    }

    public init(withScripts scripts: [Script]) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        configuration.userContentController.add(handler, name: "ios")
        for script in scripts {
            configuration.userContentController.addUserScript(WKUserScript(source: script.fileContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }

        super.init(frame: CGRect.zero, configuration: configuration)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self.evaluateJavaScript(JS)
        }
    }

    required public init?(coder: NSCoder) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        configuration.userContentController.add(handler, name: "ios")
        super.init(frame: .zero, configuration: configuration)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self.evaluateJavaScript(JS)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open func evaluateJavaScript(_ javaScriptString: String) {
        self.evaluateJavaScript(javaScriptString, completionHandler: nil)
//        {
//            (response, error) -> Void in
//            print(response)
//            print(error)
//        }
    }

    open func loadScripts(_ scripts: [Script]) {
        for script in scripts {
            self.evaluateJavaScript(script.fileContent)
//            {
//                (response, error) -> Void in
//                print(NSDate())
//                print(error)
//            }
        }
    }
}
