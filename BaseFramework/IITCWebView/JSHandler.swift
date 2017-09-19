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

class JSHandler: NSObject, WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let call = message.body as? [String: Any] else {
            NSLog("Unrecognized call %@", (message.body as AnyObject).description)
            return
        }
        guard let function = call["functionName"] as? String else {
            NSLog("Missing functionName %@", (message.body as AnyObject).description)
            return
        }
        if let args = call["args"] as? String {
            if args == "" {
                let selfSelector: Selector = NSSelectorFromString(function)
                if self.responds(to: selfSelector) {
                    self.perform(selfSelector)
                } else {
                    NSLog("%@ not implemented", function)
                }
            } else {
                let selfSelector: Selector = NSSelectorFromString(function + ":")
                if self.responds(to: selfSelector) {
                    self.perform(selfSelector, with: args)
                }
            }
        } else if (call["args"] is NSNumber || call["args"] is NSArray) {
            let selfSelector = NSSelectorFromString(function + ":")
            if (self.responds(to: selfSelector)) {
                self.perform(selfSelector, with: call["args"])
            } else {
                NSLog("%@ not implemented", function)
            }
        } else {
            NSLog((message.body as AnyObject).description)
        }
    }

    func intentPosLink(_ args: [AnyObject]) {
        guard let isPortal = args[4] as? Bool, let lat = args[0] as? Double, let lng = args[1] as? Double, let zoom: Int = args[2] as? Int else {
            return
        }
        var url: URL
        if isPortal {
            url = URL(string: "https://www.ingress.com/intel?pll=\(lat),\(lng)&z=\(zoom)")!
        } else {
            url = URL(string: "https://www.ingress.com/intel?ll=\(lat),\(lng)&z=\(zoom)")!
        }
        NotificationCenter.default.post(name: JSNotificationSharedAction, object: self, userInfo: ["data": [args[3], url, [lat, lng, zoom]]])
    }

    // share a string to the IITC share activity. only uses the share tab.

    func shareString(_ str: String) {
        NotificationCenter.default.post(name: JSNotificationSharedAction, object: self, userInfo: ["data": [str]])
    }

    // disable javascript injection while spinner is enabled
    // prevent the spinner from closing automatically

    //- (void) spinnerEnabled:(BOOL) en {
    ////    mIitc.getWebView().disableJS(en);
    //}

    // copy link to specific portal to android clipboard

    func ioscopy(_ s: String) {
        UIPasteboard.general.string = s
    }

    func switchToPane(_ paneID: String) {
        NotificationCenter.default.post(name: JSNotificationPaneChanged, object: self, userInfo: ["paneID": paneID])
    }

    //- (void) dialogFocused:(NSString *) dialogID {
    ////    mIitc.setFocusedDialog(id);
    //}


    //- (void) dialogOpened:(NSString *) dialogID withResult:(BOOL) open {
    ////    mIitc.dialogOpened(id, open);
    //}


    func bootFinished() {
        NotificationCenter.default.post(name: JSNotificationBootFinished, object: self)
    }

    // get layers and list them in a dialog

    func setLayers(_ layers: [AnyObject]) {
        NotificationCenter.default.post(name: JSNotificationLayersGot, object: self, userInfo: ["layers": layers])
    }

    //
    //- (void) addPortalHighlighter:( NSString * )name {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            mIitc.getMapSettings().addPortalHighlighter(name);
    ////        }
    ////    });
    //}
    //
    //
    //- (void) setActiveHighlighter: (NSString *) name {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            mIitc.getMapSettings().setActiveHighlighter(name);
    ////        }
    ////    });
    //}


    //- (void) updateIitc: (NSString *) fileUrl {
    //    mIitc.runOnUiThread(new Runnable() {
    //        @Override
    //        - (void) run() {
    //            mIitc.updateIitc(fileUrl);
    //        }
    //    });
    //}


    func addPane(_ pane: [AnyObject]) {
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

    //- (BOOL) showZoom {
    ////     PackageManager pm = mIitc.getPackageManager();
    ////     boolean hasMultitouch = pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN_MULTITOUCH);
    ////     boolean forcedZoom = mIitc.getPrefs().getBoolean("pref_user_zoom", false);
    ////    return forcedZoom || !hasMultitouch;
    //    return YES;
    //}


    //- (void) setFollowMode:(BOOL) follow {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            mIitc.getUserLocation().setFollowMode(follow);
    ////        }
    ////    });
    //}


    func setProgress(_ progress: NSNumber) {
        NotificationCenter.default.post(name: JSNotificationProgressChanged, object: self, userInfo: ["data": progress])
    }

    func setPermalink(_ href: String) {
        NotificationCenter.default.post(name: JSNotificationPermalinkChanged, object: self, userInfo: ["data": href])
    }

    func reloadIITC() {
        NotificationCenter.default.post(name: JSNotificationReloadRequired, object: self, userInfo: nil)
    }

}
