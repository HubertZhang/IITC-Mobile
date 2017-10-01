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
        if NSUbiquitousKeyValueStore.default.longLong(forKey: ConsoleStateKey) == 0 {
            self.setHiddenKeys(["pref_console"], animated: false)
        } else {
            self.setHiddenKeys(["pref_console_not_purchased"], animated: false)
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

    override init(style: UITableViewStyle) {
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

    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        if (specifier.key() == "pref_plugins") {
            let vc = self.navigationController!.storyboard!.instantiateViewController(withIdentifier: "pluginsViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if (specifier.key() == "pref_update") {
            let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
            hud.mode = MBProgressHUDMode.annularDeterminate
            hud.label.text = "Updating..."
            var finished = 0
            let all = ScriptsManager.sharedInstance.storedPlugins.count + 2
            ScriptsManager.sharedInstance.updatePlugins().subscribeOn(SerialDispatchQueueScheduler.init(internalSerialQueueName: "com.cradle.IITC-Mobile.network")).observeOn(MainScheduler.instance).subscribe(onNext: {
                _ -> Void in
                finished += 1
                hud.progress = Float(finished) / Float(all)
            }, onError: {
                (e) -> Void in
                print(e)
            }, onCompleted: {
                () -> Void in
                hud.label.text = "Scanning..."
                ScriptsManager.sharedInstance.loadAllPlugins()
                ScriptsManager.sharedInstance.loadUserMainScript()
                hud.hide(animated: true)
            }, onDisposed: {
                () -> Void in
            })

        } else if specifier.key() == "pref_about" {
            let vc = self.navigationController!.storyboard!.instantiateViewController(withIdentifier: "aboutViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if specifier.key() == "pref_new" {
            let vc = self.navigationController!.storyboard!.instantiateViewController(withIdentifier: "whatsNewViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if specifier.key() == "pref_adv_download_test" {
            let alert = UIAlertController(title: "Download test build", message: "Warning: download script may override IITC script you added. Continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                _ in
                let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
                hud.mode = MBProgressHUDMode.annularDeterminate
                hud.label.text = "Downloading IITC script..."

                Alamofire.download("https://iitc.me/build/test/total-conversion-build.user.js", to: {
                    _, _ -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                    let downloadPath = ScriptsManager.sharedInstance.userScriptsPath.appendingPathComponent("total-conversion-build.user.js")
                    return (downloadPath, DownloadRequest.DownloadOptions.removePreviousFile)
                }).downloadProgress {
                    progress in

                    // This closure is NOT called on the main queue for performance
                    // reasons. To update your ui, dispatch to the main queue.
                    hud.progressObject = progress
                }.response {
                    downloadResponse in

                    hud.hide(animated: true)
                    if downloadResponse.error != nil {
                        let alert1 = UIAlertController(title: "Error", message: downloadResponse.error!.localizedDescription, preferredStyle: .alert)
                        alert1.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alert1, animated: true, completion: nil)
                    }
                }

            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)

        } else if specifier.key() == "pref_console_not_purchased" {
            guard let vc = self.navigationController?.storyboard?.instantiateViewController(withIdentifier: "purchase") else {
                return
            }
            vc.modalPresentationStyle = UIModalPresentationStyle.formSheet
            self.present(vc, animated: true, completion: nil)
        } else if specifier.key() == "pref_useragent_button" {
            let vc = self.navigationController!.storyboard!.instantiateViewController(withIdentifier: "userAgentViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {

    }
}
