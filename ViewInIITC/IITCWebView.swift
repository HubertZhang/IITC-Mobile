//
//  IITCWebView.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/2/16.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit
import BaseFramework
@objc open class IITCWebView: WKWebView {

    public init(frame: CGRect) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        handler.initHandlers(for: &configuration.userContentController)
        super.init(frame: frame, configuration: configuration)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            [weak self] (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self?.evaluateJavaScript(JS, completionHandler: nil)
        }
    }

    required public init?(coder: NSCoder) {
        let configuration = WKWebViewConfiguration()
        let handler = JSHandler()
        handler.initHandlers(for: &configuration.userContentController)
        super.init(frame: .zero, configuration: configuration)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WebViewExecuteJS"), object: nil, queue: nil) {
            [weak self] (notification) -> Void in
            let JS = notification.userInfo?["JS"] as? String ?? ";"
            self?.evaluateJavaScript(JS)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
