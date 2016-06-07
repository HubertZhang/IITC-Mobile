//
//  JSHandler.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/7.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import WebKit

let JSNotificationLayersGot: String = "JSNotificationLayersGot"
let JSNotificationPaneChanged: String = "JSNotificationPaneChanged"
let JSNotificationBootFinished: String = "JSNotificationBootFinished"
let JSNotificationReloadRequired: String = "JSNotificationReloadRequired"
let JSNotificationSharedAction: String = "JSNotificationSharedAction"
let JSNotificationProgressChanged: String = "JSNotificationProgressChanged"

class JSHandler: NSObject, WKScriptMessageHandler {

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let call: [String:AnyObject] = message.body as! [String:AnyObject]
        let function = call["functionName"] as! String
        if (call["args"] is String) {
            if (call["args"] as! String == "") {
                let selfSelector: Selector = NSSelectorFromString(function)
                if self.respondsToSelector(selfSelector) {
                    self.performSelector(selfSelector)
                } else {
                    NSLog("%@ not implemented", function)
                }
            } else {
                let selfSelector: Selector = NSSelectorFromString(function.stringByAppendingString(":"))
                if self.respondsToSelector(selfSelector) {
                    self.performSelector(selfSelector, withObject: call["args"])
                }
            }
        } else if (call["args"] is NSNumber || call["args"] is NSArray) {
            let selfSelector = NSSelectorFromString(function.stringByAppendingString(":"));
            if (self.respondsToSelector(selfSelector)) {
                self.performSelector(selfSelector, withObject: call["args"]);
            } else {
                NSLog("%@ not implemented", function);
            }
        } else {
            NSLog(message.body.description);
        }
    }

    func intentPosLink(args: [AnyObject]) {
        let isPortal: Bool = args[4] as! Bool
        let lat: String = args[0] as! String
        let lng: String = args[1] as! String
        let zoom: Int = args[2] as! Int
        var url: NSURL
        if isPortal {
            url = NSURL(string: "https://www.ingress.com/intel?pll=\(lat),\(lng)&z=\(zoom)")!
        } else {
            url = NSURL(string: "https://www.ingress.com/intel?ll=\(lat),\(lng)&z=\(zoom)")!
        }
//        var locationURL = NSURL(string: "maps://?ll=\(lat),\(lng)")!
        //    NSString *title = args[3];
        //
        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationSharedAction, object: self, userInfo: ["data": [args[3], url]])
        //    mIitc.startActivity(ShareActivity.forPosition(mIitc, lat, lng, zoom, title, isPortal));
    }

    // share a string to the IITC share activity. only uses the share tab.

    func shareString(str: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationSharedAction, object: self, userInfo: ["data": [str]])
    }

    // disable javascript injection while spinner is enabled
    // prevent the spinner from closing automatically

    //- (void) spinnerEnabled:(BOOL) en {
    ////    mIitc.getWebView().disableJS(en);
    //}

    // copy link to specific portal to android clipboard

//    func copy(s: String) {
//        UIPasteboard.generalPasteboard().string = s
//    }

    func switchToPane(paneID: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationPaneChanged, object: self, userInfo: ["paneID": paneID])
    }

    //- (void) dialogFocused:(NSString *) dialogID {
    ////    mIitc.setFocusedDialog(id);
    //}


    //- (void) dialogOpened:(NSString *) dialogID withResult:(BOOL) open {
    ////    mIitc.dialogOpened(id, open);
    //}


    func bootFinished() {
        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationBootFinished, object: self)
    }
    // get layers and list them in a dialog

    func setLayers(layers: [AnyObject]) {
        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationLayersGot, object: self, userInfo: ["layers": layers])
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


    //- (void) addPane( NSString * name,  NSString * label,  NSString * icon) {
    //    mIitc.runOnUiThread(new Runnable() {
    //        @Override
    //        - (void) run() {
    //            mIitc.getNavigationHelper().addPane(name, label, icon);
    //        }
    //    });
    //}

    // some plugins may have no specific icons...add a default icon

    //- (void) addPane( NSString * name,  NSString * label) {
    //    mIitc.runOnUiThread(new Runnable() {
    //        @Override
    //        - (void) run() {
    //            mIitc.getNavigationHelper().addPane(name, label, "ic_action_new_event");
    //        }
    //    });
    //}


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


    func setProgress(progress: Int) {
        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationProgressChanged, object: self, userInfo: ["data": progress])
    }

    //- (NSString *) getFileRequestUrlPrefix {
    ////    return mIitc.getFileManager().getFileRequestPrefix();
    //    return nil;
    //}


    //- (void) setPermalink:( NSString *) href {
    ////    mIitc.setPermalink(href);
    //}


    //- (void) saveFile( NSString * filename,  NSString * type,  NSString * content) {
    //    try {
    //         File outFile = new File(Environment.getExternalStorageDirectory().getPath() +
    //                                      "/IITC_Mobile/export/" + filename);
    //        outFile.getParentFile().mkdirs();
    //
    //         FileOutputStream outStream = new FileOutputStream(outFile);
    //        outStream.write(content.getBytes("UTF-8"));
    //        outStream.close();
    //        Toast.makeText(mIitc, "File exported to " + outFile.getPath(), Toast.LENGTH_SHORT).show();
    //    } catch ( IOException e) {
    //        e.printStackTrace();
    //    }
    //}


    func reloadIITC() {

        NSNotificationCenter.defaultCenter().postNotificationName(JSNotificationReloadRequired, object: self, userInfo: nil)
    }


    //- (void) reloadIITC:(BOOL) clearCache {
    ////    mIitc.runOnUiThread(new Runnable() {
    ////        @Override
    ////        - (void) run() {
    ////            if (clearCache) mIitc.getWebView().clearCache(true);
    ////            mIitc.reloadIITC();
    ////        }
    ////    });
    //}
}
