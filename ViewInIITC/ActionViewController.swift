//
//  ActionViewController.swift
//  ViewInIITC
//
//  Created by Hubert Zhang on 16/6/10.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import MobileCoreServices
import WebKit
import BaseFramework

class ActionViewController: UIViewController, URLSessionDelegate, URLSessionDownloadDelegate {

    var webView: IITCWebViewController!

    var layersController: LayersController = LayersController.sharedInstance

    var location = IITCLocation()

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    @IBOutlet weak var backButton: UIBarButtonItem!

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.vuryleo.iitcmobile.background")
        config.sharedContainerIdentifier = ContainerIdentifier
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func syncCookie() {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        let bakCookiePath = containerPath.appendingPathComponent("Library/Cookies/Cookies.binarycookies", isDirectory: false)
        if !FileManager.default.fileExists(atPath: bakCookiePath.path) {
            return
        }

        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last!
        let cookieDirPath = libraryPath.appendingPathComponent("Cookies", isDirectory: true)
        let cookiePath = cookieDirPath.appendingPathComponent("Cookies.binarycookies", isDirectory: false)

        if FileManager.default.fileExists(atPath: cookiePath.path) {
            do {
                try FileManager.default.removeItem(atPath: cookiePath.path)
                try FileManager.default.copyItem(at: bakCookiePath, to: cookiePath)
            } catch let error {
                debugPrint("error occurred, here are the details:\n \(error)")
            }
        } else {
            try? FileManager.default.createDirectory(at: cookieDirPath, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.copyItem(at: bakCookiePath, to: cookiePath)
        }
    }

    func handleJSFileURL(_ url: URL) {
        let alert = UIAlertController(title: "Save JS File to IITC?", message: "A JavaScript file detected. Would you like to save this file to IITC (as a Plugin)?\nURL:\(url.absoluteString)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            _ in
            if url.scheme == "http" || url.scheme == "https" {
                let task = self.session.downloadTask(with: url)
                task.resume()
            } else if url.isFileURL {
                do {
                    let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
                    let userScriptsPath = containerPath.appendingPathComponent("extension", isDirectory: true)
                    let filename = url.lastPathComponent
                    let destURL = userScriptsPath.appendingPathComponent(filename)
                    try? FileManager.default.removeItem(at: destURL)
                    try FileManager.default.copyItem(at: url, to: destURL)
                } catch let e {
                    print(e.localizedDescription)
                }
            }

        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        let extensionFolder = containerPath.appendingPathComponent("extension", isDirectory: true)
        try? FileManager.default.createDirectory(at: extensionFolder, withIntermediateDirectories: true, attributes: nil)
        guard let filename = downloadTask.response?.suggestedFilename else {
            return
        }
        //        print(filename)
        let destURL = extensionFolder.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destURL)
        do {
            try FileManager.default.moveItem(at: location, to: destURL)
        } catch let e {
            print(e.localizedDescription)
        }
    }

    func configureNotification() {

    }

    var url: URL?
    func extensionURLItemHandler(item: NSSecureCoding?, error: Error!) {
        guard let wrappedURL = item as? URL else {
            return
        }
        debugPrint(wrappedURL)
        if wrappedURL.host?.contains("ingress.com") ?? false {
            self.url = wrappedURL
            OperationQueue.main.addOperation {
                self.webView.load(url: wrappedURL)
            }
        } else if wrappedURL.host == "maps.apple.com" {
            let components = URLComponents(url: wrappedURL, resolvingAgainstBaseURL: false)!
            guard let queryItems = components.queryItems else {
                return
            }
            let ll = queryItems.filter({
                return $0.name == "ll"
            })
            if ll.count > 0 {
                var newURLComponents = URLComponents(string: "https://intel.ingress.com/intel")!
                newURLComponents.queryItems = [ll[0]]
                if let newURL = newURLComponents.url {
                    OperationQueue.main.addOperation {
                        self.webView.load(url: newURL)
                    }
                }
            }
        } else if wrappedURL.pathExtension == "js" {
            OperationQueue.main.addOperation {
                self.webView.load(htmlString: "JSFile")
                self.handleJSFileURL(wrappedURL)
            }
        } else {
            OperationQueue.main.addOperation {
                self.webView.load(htmlString: "Link not supported:\(wrappedURL.absoluteString)")
            }
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNotification()
        syncCookie()
    }

    override func viewDidAppear(_ animated: Bool) {
        var founded = false
        for item in self.extensionContext?.inputItems ?? [] where item is NSExtensionItem {
            guard let inputItem = item as? NSExtensionItem else {
                continue
            }
            for provider in inputItem.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                founded = true
                provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: self.extensionURLItemHandler)

            }
        }
        if !founded {
            self.webView.load(htmlString: "Link not supported")
        }
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
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

    @IBAction func reloadButtonPressed(_ aa: AnyObject) {
        NotificationCenter.default.post(name: JSNotificationReloadRequired, object: nil)
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
}

extension ActionViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: {
            _ -> Void in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: nil)
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
        self.present(alertController, animated: true, completion: nil)
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
        self.present(alertController, animated: true, completion: nil)
    }

}
