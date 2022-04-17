//
//  JSHandler.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit

public let JSNotificationLayersGot = Notification.Name(rawValue: "JSNotificationLayersGot")
public let JSNotificationPaneChanged = Notification.Name(rawValue: "JSNotificationPaneChanged")
public let JSNotificationBootFinished = Notification.Name(rawValue: "JSNotificationBootFinished")
public let JSNotificationReloadRequired = Notification.Name(rawValue: "JSNotificationReloadRequired")
public let JSNotificationSharedAction = Notification.Name(rawValue: "JSNotificationSharedAction")
public let JSNotificationProgressChanged = Notification.Name(rawValue: "JSNotificationProgressChanged")
public let JSNotificationPermalinkChanged = Notification.Name(rawValue: "JSNotificationPermalinkChanged")
public let JSNotificationAddPane = Notification.Name(rawValue: "JSNotificationAddPane")
public let JSNotificationSaveFile = Notification.Name(rawValue: "JSNotificationSaveFile")

open class JSHandler: NSObject, WKScriptMessageHandler {

    static let interfaces = ["addPane", "addPortalHighlighter", "bootFinished", "ioscopy", "dialogFocused", "dialogOpened", "getFileRequestUrlPrefix", "getVersionCode", "getVersionName", "intentPosLink", "reloadIITC", "saveFile", "setActiveHighlighter", "setFollowMode", "setLayers", "setPermalink", "setProgress", "shareString", "showZoom", "spinnerEnabled", "switchToPane", "updateIitc"]

    open func initHandlers(`for` userContentController: inout WKUserContentController) {
        for interface in JSHandler.interfaces {
            userContentController.add(self, name: interface)
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let interface = message.name
        let arg = message.body
        if arg is NSNull {
            let selfSelector: Selector = NSSelectorFromString(interface)
            if self.responds(to: selfSelector) {
                self.perform(selfSelector)
            } else {
                NSLog("%@ not implemented", interface)
            }
        } else {
            let selfSelector: Selector = NSSelectorFromString(interface + ":")
            if self.responds(to: selfSelector) {
                self.perform(selfSelector, with: arg)
            } else {
                NSLog("%@ not implemented", interface)
            }
        }
    }

    @objc func intentPosLink(_ args: Any) {
        // [Lat, Lng, Zoom, Title, isPortal]
        guard let args = args as? [AnyObject] else {
            return
        }
        if args.count < 5 {
            return
        }
        guard let isPortal = args[4] as? Bool, let lat = args[0] as? Double, let lng = args[1] as? Double, let zoom: Int = args[2] as? Int else {
            return
        }
        var url: URL
        if isPortal {
            url = URL(string: "https://intel.ingress.com/intel?pll=\(lat),\(lng)&z=\(zoom)")!
        } else {
            url = URL(string: "https://intel.ingress.com/intel?ll=\(lat),\(lng)&z=\(zoom)")!
        }
        NotificationCenter.default.post(name: JSNotificationSharedAction, object: self, userInfo: ["data": [args[3], url, ["lat": lat, "lng": lng, "zoom": zoom]]])
    }

    // share a string to the IITC share activity. only uses the share tab.

    @objc func shareString(_ str: Any) {
        guard let str = str as? String else {
            return
        }
        NotificationCenter.default.post(name: JSNotificationSharedAction, object: self, userInfo: ["data": [str]])
    }

    // disable javascript injection while spinner is enabled
    // prevent the spinner from closing automatically

    // - (void) spinnerEnabled:(BOOL) en {
    ////    mIitc.getWebView().disableJS(en);
    // }

    // copy link to specific portal to android clipboard

    @objc func ioscopy(_ s: Any) {
        guard let s = s as? String else {
            return
        }
        UIPasteboard.general.string = s
    }

    @objc func switchToPane(_ paneID: Any) {
        guard let paneID = paneID as? String else {
            return
        }
        NotificationCenter.default.post(name: JSNotificationPaneChanged, object: self, userInfo: ["paneID": paneID])
    }

    // - (void) dialogFocused:(NSString *) dialogID {
    ////    mIitc.setFocusedDialog(id);
    // }

    // - (void) dialogOpened:(NSString *) dialogID withResult:(BOOL) open {
    ////    mIitc.dialogOpened(id, open);
    // }

    @objc func bootFinished() {
        NotificationCenter.default.post(name: JSNotificationBootFinished, object: self)
    }

    // get layers and list them in a dialog

    @objc func setLayers(_ layers: Any) {
        guard let layers = layers as? [String] else {
            return
        }
        NotificationCenter.default.post(name: JSNotificationLayersGot, object: self, userInfo: ["layers": layers])
    }

    //
    // - (void) addPortalHighlighter:( NSString * )name {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            mIitc.getMapSettings().addPortalHighlighter(name);
    ////        }
    ////    });
    // }
    //
    //
    // - (void) setActiveHighlighter: (NSString *) name {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            mIitc.getMapSettings().setActiveHighlighter(name);
    ////        }
    ////    });
    // }

    // - (void) updateIitc: (NSString *) fileUrl {
    //    mIitc.runOnUiThread(new Runnable() {
    //        @Override
    //        - (void) run() {
    //            mIitc.updateIitc(fileUrl);
    //        }
    //    });
    // }

    @objc func saveFile(_ args: Any) {
        guard let args = args as? [AnyObject] else {
            return
        }
        if args.count != 3 {
            return
        }
        guard let fileName = args[0] as? String else {
            return
        }
        guard let fileType = args[1] as? String else {
            return
        }
        guard let fileContent = args[2] as? String else {
            return
        }
        NotificationCenter.default.post(name: JSNotificationSaveFile, object: self, userInfo: ["fileName": fileName, "fileType": fileType, "fileContent": fileContent])
    }

    @objc func addPane(_ pane: Any) {
        guard let pane = pane as? [AnyObject] else {
            return
        }
        if pane.count < 2 {
            return
        }
        guard let name = pane[0] as? String else {
            return
        }
        guard let label = pane[1] as? String else {
            return
        }
        var icon = "ic_action_new_event"
        if pane.count >= 3 {
            icon = pane[2] as? String ?? "ic_action_new_event"
        }
        NotificationCenter.default.post(name: JSNotificationAddPane, object: self, userInfo: ["name": name, "label": label, "icon": icon])

    }

    // - (BOOL) showZoom {
    ////     PackageManager pm = mIitc.getPackageManager();
    ////     boolean hasMultitouch = pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN_MULTITOUCH);
    ////     boolean forcedZoom = mIitc.getPrefs().getBoolean("pref_user_zoom", false);
    ////    return forcedZoom || !hasMultitouch;
    //    return YES;
    // }

    // - (void) setFollowMode:(BOOL) follow {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            mIitc.getUserLocation().setFollowMode(follow);
    ////        }
    ////    });
    // }

    @objc func setProgress(_ progress: Any) {
        guard let progress = progress as? NSNumber else {
            return
        }
        NotificationCenter.default.post(name: JSNotificationProgressChanged, object: self, userInfo: ["data": progress])
    }

    @objc func setPermalink(_ href: Any) {
        guard let href = href as? String else {
            return
        }
        NotificationCenter.default.post(name: JSNotificationPermalinkChanged, object: self, userInfo: ["data": href])
    }

    @objc func reloadIITC() {
        NotificationCenter.default.post(name: JSNotificationReloadRequired, object: self, userInfo: nil)
    }

}
