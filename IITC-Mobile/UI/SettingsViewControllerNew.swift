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

@objc class SettingsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    let disposeBag = DisposeBag()

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
        NotificationCenter.default.addObserver(forName: NSNotification.Name.IASKSettingChanged, object: nil, queue: .main) { [weak self] (_) in
            self?.dirty = true
        }
    }

    let defaults = sharedUserDefaults

    var dirty: Bool = false
    override init(style: UITableView.Style) {
        super.init(style: style)
        self.settingsStore = IASKSettingsStoreUserDefaults(userDefaults: defaults)
        self.clearsSelectionOnViewWillAppear = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        if self.dirty {
            NotificationCenter.default.post(name: JSNotificationReloadRequired, object: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    func pushViewController(withIdentifier identifier: String, config: (UIViewController) -> Void = {_ in return}) {
        guard let vc = self.navigationController?.storyboard?.instantiateViewController(withIdentifier: identifier) else {
            return
        }
        config(vc)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController, buttonTappedFor specifier: IASKSpecifier) {
        switch specifier.key {
        case "pref_plugins":
            self.pushViewController(withIdentifier: "pluginsViewController")
        case "pref_about":
            self.pushViewController(withIdentifier: "textViewController") {(vc) in
                guard let vc = vc as? TextViewController else {
                    return
                }
                vc.title = "About"
                vc.attrStringBuilder = {
                    let path = Bundle.main.url(forResource: "About", withExtension: "html")
                    return loadHtmlFileToAttributeString(path!)
                }
            }
        case "pref_new":
            self.pushViewController(withIdentifier: "textViewController") {(vc) in
                guard let vc = vc as? TextViewController else {
                    return
                }
                vc.title = "What's New"
                vc.attrStringBuilder = {
                    let path = Bundle.main.url(forResource: "WhatsNew", withExtension: "html")
                    return loadHtmlFileToAttributeString(path!)
                }
            }
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
        let (o, p) = ScriptsManager.sharedInstance.updatePlugins()
        hud.progressObject = p
        o.subscribeOn(SerialDispatchQueueScheduler.init(internalSerialQueueName: "com.vuryleo.iitcmobile.network"))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                _ -> Void in
            }, onError: {
                (e) -> Void in
                print(e)
            }, onCompleted: {
                () -> Void in
                hud.label.text = "Scanning..."
                DispatchQueue.global().async(execute: {
                    ScriptsManager.sharedInstance.reloadScripts()
                    DispatchQueue.main.async(execute: {
                        hud.hide(animated: true)
                    })
                })
            }, onDisposed: {
                () -> Void in
            }).disposed(by: self.disposeBag)
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {

    }
}
