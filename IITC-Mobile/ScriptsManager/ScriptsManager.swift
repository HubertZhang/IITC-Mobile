//
//  ScriptsManager.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class ScriptsManager: NSObject {
    static let sharedInstance = ScriptsManager()

    var storedPlugins = [Script]()
    var loadedPluginNames: [String]
    var loadedPlugins: Set<String>

    var mainScript: Script
    var hookScript: Script
    var positionScript: Script

    var initialScriptsPath: NSURL
    var initialPluginsPath: NSURL
    var userScriptsPath: NSURL
    var userPluginsPath: NSURL

    override init() {
        initialScriptsPath = NSBundle.mainBundle().resourceURL!.URLByAppendingPathComponent("scripts", isDirectory: true)
        initialPluginsPath = initialScriptsPath.URLByAppendingPathComponent("plugins", isDirectory: true)
        userScriptsPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        userPluginsPath = userScriptsPath.URLByAppendingPathComponent("plugins", isDirectory: true)
        mainScript = try! Script(atFilePath: initialScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js"))
        hookScript = try! Script(coreJS: initialScriptsPath.URLByAppendingPathComponent("ios-hooks.js"), withName: "hook")
        hookScript.fileContent = String(format: hookScript.fileContent, "1.0", 20)
        positionScript = try! Script(coreJS: initialScriptsPath.URLByAppendingPathComponent("user-location.user.js"), withName: "position")
        loadedPluginNames = NSUserDefaults.standardUserDefaults().arrayForKey("LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)
        super.init()
        loadUserMainScript()
        loadAllPlugins()

    }

    func loadAllPlugins() {
        self.storedPlugins = loadPluginInDirectory(initialPluginsPath)
        for plugin in loadPluginInDirectory(userPluginsPath) {
            let index = storedPlugins.indexOf {
                oldPlugin -> Bool in
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
            do {
                mainScript = try Script(atFilePath: userURL)
            } catch {

            }
        }
    }

    func loadPluginInDirectory(url: NSURL) -> [Script] {
        try! NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        let directoryContents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
        var result = [Script]()
        for pluginPath in directoryContents {
            if pluginPath.path!.hasSuffix(".meta.js") {
                continue
            }
            do {
                try result.append(Script(atFilePath: pluginPath))
            } catch {
                continue
            }
        }
        return result
    }

    func getLoadedScripts() -> [Script] {
        var result = [Script]()
        result.append(mainScript)
        result.append(hookScript)
        result.append(positionScript)
        for name in loadedPluginNames {
            let index = storedPlugins.indexOf {
                plugin -> Bool in
                return plugin.fileName == name
            }
            if index != nil {
                result.append(storedPlugins[index!])
            }
        }
        return result
    }

    func setPlugin(script: Script, loaded: Bool) {
        let index = loadedPluginNames.indexOf {
            plugin -> Bool in
            return plugin == script.fileName
        }
        if index != nil && !loaded {
            loadedPluginNames.removeAtIndex(index!)
        } else if index == nil && loaded {
            loadedPluginNames.append(script.fileName)
        }
        loadedPlugins = Set<String>(loadedPluginNames)
        NSUserDefaults.standardUserDefaults().setObject(loadedPluginNames, forKey: "LoadedPlugins")
    }

    func updatePlugins() {

    }
}
