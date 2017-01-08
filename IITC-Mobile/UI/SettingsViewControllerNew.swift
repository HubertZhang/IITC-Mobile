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

    override func viewDidLoad() {
        self.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "Settings")

        let builder = GAIDictionaryBuilder.createScreenView()!
        tracker?.send(builder.build() as NSDictionary as! [AnyHashable: Any])
        for index in self.tableView.indexPathsForSelectedRows ?? [] {
            self.tableView.deselectRow(at: index, animated: true)
        }
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
        let defaults = UserDefaults(suiteName: ContainerIdentifier)
        self.settingsStore = IASKSettingsStoreUserDefaults(userDefaults: defaults)
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
            let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true);
            hud.mode = MBProgressHUDMode.annularDeterminate;
            hud.label.text = "Updating...";
            var finished = 0
            let all = ScriptsManager.sharedInstance.storedPlugins.count + 2
            ScriptsManager.sharedInstance.updatePlugins().subscribeOn(SerialDispatchQueueScheduler.init(internalSerialQueueName: "com.cradle.IITC-Mobile.network")).observeOn(MainScheduler.instance).subscribe(onNext: {
                (result) -> Void in
                finished = finished + 1
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
                action in
                let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true);
                hud.mode = MBProgressHUDMode.annularDeterminate;
                hud.label.text = "Downloading IITC script...";

                Alamofire.download("https://iitc.me/build/test/total-conversion-build.user.js", to: {
                    (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
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

        }
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {

    }
}
