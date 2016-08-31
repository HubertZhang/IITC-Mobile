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
import RxCocoa
import RxBlocking
import InAppSettingsKit
import MBProgressHUD
import Alamofire

@objc class SettingsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {

    override func viewDidLoad() {
        self.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Settings")

        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject:AnyObject])
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
        let defaults = NSUserDefaults(suiteName: ContainerIdentifier)
        self.settingsStore = IASKSettingsStoreUserDefaults(userDefaults: defaults)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    func settingsViewController(sender: IASKAppSettingsViewController!, buttonTappedForSpecifier specifier: IASKSpecifier!) {
        if (specifier.key() == "pref_plugins") {
            let vc = self.navigationController!.storyboard!.instantiateViewControllerWithIdentifier("pluginsViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if (specifier.key() == "pref_update") {
            let hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true);
            hud.mode = MBProgressHUDMode.AnnularDeterminate;
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
                hud.hideAnimated(true)
            }, onDisposed: {
                () -> Void in
            })

        } else if specifier.key() == "pref_about" {
            let vc = self.navigationController!.storyboard!.instantiateViewControllerWithIdentifier("aboutViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if specifier.key() == "pref_new" {
            let vc = self.navigationController!.storyboard!.instantiateViewControllerWithIdentifier("whatsNewViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if specifier.key() == "pref_adv_download_test" {
            let alert = UIAlertController(title: "Download test build", message: "Warning: download script may override IITC script you added. Continue?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
                action in
                let hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true);
                hud.mode = MBProgressHUDMode.AnnularDeterminate;
                hud.label.text = "Downloading IITC script...";

                Alamofire.download(.GET, "https://secure.jonatkins.com/iitc/test/total-conversion-build.user.js", destination: {
                    (url, response) -> NSURL in
                    let pathComponent = response.suggestedFilename
                    let downloadPath = ScriptsManager.sharedInstance.userScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js")
                    if NSFileManager.defaultManager().fileExistsAtPath(downloadPath.path!) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(downloadPath.path!)
                        } catch {

                        }
                    }
                    return downloadPath
                }).progress {
                    bytesRead, totalBytesRead, totalBytesExpectedToRead in

                    // This closure is NOT called on the main queue for performance
                    // reasons. To update your ui, dispatch to the main queue.
                    dispatch_async(dispatch_get_main_queue()) {
                        hud.progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    }
                }.response {
                    request, response, _, error in

                    hud.hideAnimated(true)
                    if error != nil {
                        let alert1 = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: .Alert)
                        alert1.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                        self.presentViewController(alert1, animated: true, completion: nil)
                    }
                }

            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

            self.presentViewController(alert, animated: true, completion: nil)

        }
    }

    func settingsViewControllerDidEnd(sender: IASKAppSettingsViewController!) {

    }
}
