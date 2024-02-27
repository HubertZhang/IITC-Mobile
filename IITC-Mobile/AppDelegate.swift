//
//  AppDelegate.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase
import BaseFramework
import StoreKit

import QuickLook

var sharedUserDefaults = UserDefaults(suiteName: ContainerIdentifier)!

var NotificationLinkDetected = Notification.Name("NotificationLinkDetected")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        SKPaymentQueue.default().add(InAppPurchaseManager.default)

        FirebaseApp.configure()

        let hud = MBProgressHUD.showAdded(to: self.window!.rootViewController!.view, animated: true)
        DispatchQueue.global().async(execute: {
            _ = ScriptsManager.sharedInstance.getLoadedScripts()
            DispatchQueue.main.async(execute: {
                hud.hide(animated: true)
            })
        })

        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.saveFile(_:)), name: JSNotificationSaveFile, object: nil)

        #if targetEnvironment(macCatalyst)
        if let titlebar = window!.windowScene?.titlebar {
          titlebar.titleVisibility = .hidden
          titlebar.toolbar = nil
        }
        #endif

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    var lastSeenPastedLink: String?

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIPasteboard.general.detectValues(for: [UIPasteboard.DetectionPattern.probableWebURL], completionHandler: { [self] result in
            switch result {
            case .success(let detectionPatterns):
                guard let link = detectionPatterns[.probableWebURL] as? String else {
                    return
                }
                // print("Link detected: \(link)")
                if link == lastSeenPastedLink {
                    return
                }
                lastSeenPastedLink = link
                // print("New link seen, comfirming...")
                NotificationCenter.default.post(name: NotificationLinkDetected, object: nil, userInfo: ["link": link])
            case .failure(let error):
                print("Error detecting url: \(error.localizedDescription)")
            }
        })
        ScriptsManager.sharedInstance.synchronizeExtensionFolder()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        SKPaymentQueue.default().remove(InAppPurchaseManager.default)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == "iitc" {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return false
            }
            setInitialQueryItems(components.queryItems)
            NotificationCenter.default.post(name: JSNotificationReloadRequired, object: nil)
            return true
        }
        if url.pathExtension != "js" {
            return false
        }

        var fileUrl = url

        if let canOpen = options[.openInPlace] as? Bool, !canOpen {
            do {
                let tempPath = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
                try FileManager.default.copyItem(at: url, to: tempPath.appendingPathComponent(url.lastPathComponent))
                fileUrl = tempPath.appendingPathComponent(url.lastPathComponent)
            } catch let e {
                let alert = UIAlertController(title: "Failed to import JS File", message: "When importing file at \(url), an error occured: \(e.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }

        do {
            let script = try Script.init(atFilePath: fileUrl)
            let alert = UIAlertController(title: "Save JS File to IITC?", message: "A JavaScript file detected. Would you like to save this file to IITC (as a Plugin)?\nName:\(script.name ?? "undefined")\nCategory:\(script.category)\nVersion:\(script.version ?? "unknown")", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                _ in
                if fileUrl.isFileURL {
                    do {
                        let userScriptsPath = ScriptsManager.sharedInstance.userScriptsPath
                        let filename = fileUrl.lastPathComponent
                        let destURL = userScriptsPath.appendingPathComponent(filename)
                        try? FileManager.default.removeItem(at: destURL)
                        try FileManager.default.copyItem(at: fileUrl, to: destURL)
                        ScriptsManager.sharedInstance.reloadScripts()
                    } catch let e {
                        print(e.localizedDescription)
                    }
                }

            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        } catch let e {
            let alert = UIAlertController(title: "Failed to parse JS File", message: "When parsing file at \(url), an error occured: \(e.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
        return true
    }

    var tempFile: TempFile!
    @objc func saveFile(_ notification: Notification) {
        let fileName = notification.userInfo?["fileName"] as? String ?? "downloadFile"
        let fileType = notification.userInfo?["fileType"] as? String ?? ""
        guard let fileContent = notification.userInfo?["fileContent"] as? String else {
            return
        }
        guard var tempURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return
        }
        do {
            tempURL.appendPathComponent("download", isDirectory: true)
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
            tempURL.appendPathComponent(fileName)
            let data = fileContent.data(using: .utf8)
            try data?.write(to: tempURL)
        } catch _ {
            return
        }
        tempFile = TempFile(fileURL: tempURL as NSURL, type: fileType)

        let vc = QLPreviewController()
        vc.dataSource = tempFile
        vc.title = "Downloaded File"
        self.topViewController()?.present(vc, animated: true)
    }

    func topViewController() -> UIViewController? {
        var v = self.window?.rootViewController
        while v?.presentedViewController != nil {
            v = v?.presentedViewController
        }
        return v
    }
}

class TempFile: QLPreviewControllerDataSource {
    var fileURL: NSURL
    var fileType: String

    init(fileURL: NSURL, type: String) {
        self.fileURL = fileURL
        self.fileType = type
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.fileURL
    }
}
