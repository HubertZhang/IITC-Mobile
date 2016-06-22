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

@objc class SettingsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {

    override func viewDidLoad() {
        self.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Settings")
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
        let defaults = NSUserDefaults(suiteName: ContainerIdentifier)
        self.settingsStore = IASKSettingsStoreUserDefaults(userDefaults: defaults)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func settingsViewController(sender: IASKAppSettingsViewController!, buttonTappedForSpecifier specifier: IASKSpecifier!) {
        if (specifier.key() == "pref_plugins") {
            let vc = self.navigationController!.storyboard!.instantiateViewControllerWithIdentifier("pluginsViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if (specifier.key() == "pref_update") {
            let hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true);
            hud.mode = MBProgressHUDMode.AnnularDeterminate;
            hud.labelText = "Updating...";
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
                hud.labelText = "Scanning..."
                ScriptsManager.sharedInstance.loadAllPlugins()
                ScriptsManager.sharedInstance.loadUserMainScript()
                hud.hide(true)
            }, onDisposed: {
                () -> Void in
            })

        } else if specifier.key() == "pref_about" {
            let vc = self.navigationController!.storyboard!.instantiateViewControllerWithIdentifier("aboutViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        } else if specifier.key() == "pref_new" {
            let vc = self.navigationController!.storyboard!.instantiateViewControllerWithIdentifier("whatsNewViewController")
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }

    func settingsViewControllerDidEnd(sender: IASKAppSettingsViewController!) {

    }
}
