//
//  ScriptsManager.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class ScriptsManager: NSObject {
    let sharedInstance = ScriptsManager()
    
    var storedPlugins = [Script]()
    var loadedPluginNames : [String]
    
    var mainScript : Script
    var hookScript : Script
    var positionScript : Script
    
    var initialScriptsPath : NSURL
    var initialPluginsPath : NSURL
    var userScriptsPath : NSURL
    var userPluginsPath : NSURL
    
    override init() {
        initialScriptsPath = NSBundle.mainBundle().resourceURL!.URLByAppendingPathComponent("scripts", isDirectory: true)
        initialPluginsPath = initialScriptsPath.URLByAppendingPathComponent("plugins", isDirectory: true)
        userScriptsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        userPluginsPath = userScriptsPath.URLByAppendingPathComponent("plugins", isDirectory: true)
        mainScript = Script(atFilePath: initialScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js"))
        hookScript = Script(atFilePath: initialScriptsPath.URLByAppendingPathComponent("ios-hooks.js"))
        positionScript = Script(atFilePath: initialScriptsPath.URLByAppendingPathComponent("user-location.user.js"))
        loadedPluginNames = NSUserDefaults.standardUserDefaults().arrayForKey("LoadedPlugins") as? [String] ?? [String]()
        
        super.init()
        loadUserMainScript()
        loadAllPlugins()
        
    }
    
    func loadAllPlugins() {
        self.storedPlugins = loadPluginInDirectory(initialPluginsPath)
        for plugin in loadPluginInDirectory(userPluginsPath) {
            let index = storedPlugins.indexOf{ oldPlugin -> Bool in
                return oldPlugin.fileName == plugin.fileName
            }
            if index != nil {
                storedPlugins[index!] = plugin
            } else {
                storedPlugins.append(plugin)
            }
        }
    }
    
    func loadUserMainScript() {
        let userURL = userScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js")
        if NSFileManager.defaultManager().fileExistsAtPath(userURL.path!) {
            mainScript = Script(atFilePath:userURL)
        }
    }
    
    func loadPluginInDirectory(url:NSURL) -> [Script] {
        let directoryContents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
        var result = [Script]()
        for pluginPath in directoryContents {
            if pluginPath.path!.hasSuffix(".meta.js") {
                continue
            }
            result.append(Script(atFilePath: pluginPath))
        }
        return result
    }
    
    func getLoadedPlugins() -> [Script] {
        var result = [Script]()
        for name in loadedPluginNames {
            let index = storedPlugins.indexOf{ plugin -> Bool in
                return plugin.fileName == name
            }
            if index != nil {
                result.append(storedPlugins[index!])
            }
        }
        return result
    }
    
    func setPlugin(script:Script, loaded : Bool) {
        let index = loadedPluginNames.indexOf{ plugin -> Bool in
            return plugin == script.fileName
        }
        if index != nil && !loaded {
            loadedPluginNames.removeAtIndex(index!)
        } else if index == nil && loaded {
            loadedPluginNames.append(script.fileName)
        }
        NSUserDefaults.standardUserDefaults().setObject(loadedPluginNames, forKey: "LoadedPlugins")
    }

    func updatePlugins() {
        
    }
}
