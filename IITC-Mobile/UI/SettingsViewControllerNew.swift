//
//  SettingsViewControllerNew.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 15/9/27.
//  Copyright © 2015年 IITC. All rights reserved.
//

import UIKit
import BaseFramework
import RxSwift
import InAppSettingsKit
import MBProgressHUD
import Alamofire
import FirebaseAnalytics

@objc class SettingsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
#if !DEBUG
        if InAppPurchaseManager.default.consolePurchased {
            self.setHiddenKeys(["pref_console_not_purchased"], animated: false)
        } else {
            self.setHiddenKeys(["pref_console"], animated: false)
        }
#endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.logEvent("enter_screen", parameters: [
            "screen_name": "Settings"
        ])
    }

    let defaults = UserDefaults(suiteName: ContainerIdentifier)

    override init(style: UITableView.Style) {
        super.init(style: style)
        self.settingsStore = IASKSettingsStoreUserDefaults(userDefaults: defaults)
        self.clearsSelectionOnViewWillAppear = true
        defaults?.addObserver(self, forKeyPath: "pref_console", options: [.old, .new], context: nil)
    }

    deinit {
        defaults?.removeObserver(self, forKeyPath: "pref_console")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "pref_console" {
            guard let change = change else {
                return
            }
            let oldKey = (change[.oldKey] as? NSNumber)?.boolValue ?? false
            let newKey = (change[.newKey] as? NSNumber)?.boolValue ?? false
            if oldKey != newKey {
                let alert = UIAlertController(title: "Change not applied yet", message: "Please restart IITC-iOS to enable or disable Debug Console", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    func pushViewController(withIdentifier identifier: String) {
        guard let vc = self.navigationController?.storyboard?.instantiateViewController(withIdentifier: identifier) else {
            return
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        switch specifier.key() {
        case "pref_plugins":
            self.pushViewController(withIdentifier: "pluginsViewController")
        case "pref_about":
            self.pushViewController(withIdentifier: "aboutViewController")
        case "pref_new":
            self.pushViewController(withIdentifier: "whatsNewViewController")
        case "pref_useragent_button":
            self.pushViewController(withIdentifier: "userAgentViewController")
        case "pref_console_not_purchased":
            guard let vc = self.navigationController?.storyboard?.instantiateViewController(withIdentifier: "purchase") else {
                return
            }
            vc.modalPresentationStyle = UIModalPresentationStyle.formSheet
            self.present(vc, animated: true, completion: nil)
        case "pref_update":
            self.startUpdatePlugins()
        case "pref_adv_download_test":
            let alert = UIAlertController(title: "Download test build of IITC", message: "Warning: downloaded script may override IITC script you added. Continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: self.startDownloadIITCScript))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
            break
        default:
            return
        }
    }

    func startDownloadIITCScript(_ action: UIAlertAction) {
        let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        hud.mode = MBProgressHUDMode.annularDeterminate
        hud.label.text = "Downloading IITC script..."

        Alamofire.download("https://iitc.me/build/test/total-conversion-build.user.js", to: {
            _, _ -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            let downloadPath = ScriptsManager.sharedInstance.userScriptsPath.appendingPathComponent("total-conversion-build.user.js")
            return (downloadPath, DownloadRequest.DownloadOptions.removePreviousFile)
        }).downloadProgress(queue: DispatchQueue.main, closure: {
            progress in

            // This closure is NOT called on the main queue for performance
            // reasons. To update your ui, dispatch to the main queue.
            hud.progressObject = progress
        }).response(queue: DispatchQueue.main, completionHandler: {
            downloadResponse in

            hud.hide(animated: true)
            if downloadResponse.error != nil {
                let alert1 = UIAlertController(title: "Error", message: downloadResponse.error!.localizedDescription, preferredStyle: .alert)
                alert1.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert1, animated: true, completion: nil)
            }
        })
    }

    func startUpdatePlugins() {
        let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        hud.mode = MBProgressHUDMode.annularDeterminate
        hud.label.text = "Updating..."
        var finished = 0
        let all = ScriptsManager.sharedInstance.storedPlugins.count + 2
        ScriptsManager.sharedInstance.updatePlugins()
            .subscribeOn(SerialDispatchQueueScheduler.init(internalSerialQueueName: "com.cradle.IITC-Mobile.network"))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                _ -> Void in
                finished += 1
                hud.progress = Float(finished) / Float(all)
            }, onError: {
                (e) -> Void in
                print(e)
            }, onCompleted: {
                () -> Void in
                hud.label.text = "Scanning..."
                DispatchQueue.global().async(execute: {
                    ScriptsManager.sharedInstance.loadAllPlugins()
                    ScriptsManager.sharedInstance.loadUserMainScript()
                    DispatchQueue.main.async(execute: {
                        hud.hide(animated: true)
                    })
                })
            }, onDisposed: {
                () -> Void in
            })
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {

    }
}
