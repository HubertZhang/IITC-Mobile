//
//  ScriptsManager.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit
import RxSwift
import Alamofire
import RxAlamofire

public let ScriptsUpdatedNotification: String = "ScriptsUpdatedNotification"
public let ContainerIdentifier: String = "group.com.vuryleo.iitc"

public class ScriptsManager: NSObject, DirectoryWatcherDelegate {
    public static let sharedInstance = ScriptsManager()

    public var storedPlugins = [Script]()
    var loadedPluginNames: [String]
    public var loadedPlugins: Set<String>

    public var mainScript: Script
    var hookScript: Script
    public var positionScript: Script

    var libraryScriptsPath: NSURL
    var libraryPluginsPath: NSURL
    public var userScriptsPath: NSURL
    var documentPath: NSURL

    var documentWatcher: DirectoryWatcher?
    var containerWatcher: DirectoryWatcher?
    
    var userDefaults = NSUserDefaults(suiteName: ContainerIdentifier)!
    
    override init() {
        let containerPath = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(ContainerIdentifier)!
        libraryScriptsPath = containerPath.URLByAppendingPathComponent("scripts", isDirectory: true)
        libraryPluginsPath = libraryScriptsPath.URLByAppendingPathComponent("plugins", isDirectory: true)
        userScriptsPath = containerPath.URLByAppendingPathComponent("userScripts", isDirectory: true)
        try? NSFileManager.defaultManager().createDirectoryAtURL(userScriptsPath, withIntermediateDirectories: true, attributes: nil)
        documentPath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        let mainScriptPath = libraryScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js")
        if !NSFileManager.defaultManager().fileExistsAtPath(mainScriptPath.path!) {
            try? NSFileManager.defaultManager().createDirectoryAtURL(containerPath, withIntermediateDirectories: true, attributes: nil)
            try? NSFileManager.defaultManager().removeItemAtURL(libraryScriptsPath)
            try! NSFileManager.defaultManager().copyItemAtURL(NSBundle(forClass:ScriptsManager.classForCoder()).resourceURL!.URLByAppendingPathComponent("scripts", isDirectory: true), toURL: libraryScriptsPath)
        }
        mainScript = try! Script(atFilePath: libraryScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js"))
        mainScript.category = "Core"
        hookScript = try! Script(coreJS: libraryScriptsPath.URLByAppendingPathComponent("ios-hooks.js"), withName: "hook")
        hookScript.fileContent = String(format: hookScript.fileContent, "1.0", 20)
        positionScript = try! Script(coreJS: libraryScriptsPath.URLByAppendingPathComponent("user-location.user.js"), withName: "position")
        loadedPluginNames = userDefaults.arrayForKey("LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)

        super.init()
//        print(userScriptsPath.absoluteString)
        syncDocumentAndContainer()
        documentWatcher = DirectoryWatcher(documentPath, delegate: self)
        containerWatcher = DirectoryWatcher(userScriptsPath, delegate: self)
        
        loadUserMainScript()
        loadAllPlugins()

    }

    public func loadAllPlugins() {
        self.storedPlugins = loadPluginInDirectory(libraryPluginsPath)
        for plugin in loadPluginInDirectory(userScriptsPath) {
            plugin.isUserScript = true
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

    public func loadUserMainScript() {
        let userURL = userScriptsPath.URLByAppendingPathComponent("total-conversion-build.user.js")
        if NSFileManager.defaultManager().fileExistsAtPath(userURL.path!) {
            do {
                mainScript = try Script(atFilePath: userURL)
                mainScript.category = "Core"
                mainScript.isUserScript = true
            } catch {

            }
        }
    }

    func loadPluginInDirectory(url: NSURL) -> [Script] {
        try! NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        guard let directoryContents = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles) else {
            return []
        }
        var result = [Script]()
        for pluginPath in directoryContents {
            if !pluginPath.path!.hasSuffix(".js") {
                continue
            }
            if pluginPath.path!.hasSuffix(".meta.js") {
                continue
            }
            if pluginPath.lastPathComponent == "total-conversion-build.user.js" {
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

    public func getLoadedScripts() -> [Script] {
        var result = [Script]()
        result.append(mainScript)
        result.append(hookScript)
        for name in loadedPluginNames {
            let index = storedPlugins.indexOf {
                plugin -> Bool in
                return plugin.fileName == name
            }
            if index != nil {
                if name == "canvas-render.user.js" {
                    result.insert(storedPlugins[index!], atIndex: 0)
                } else {
                    result.append(storedPlugins[index!])
                }
            }
        }
        return result
    }

    public func setPlugin(script: Script, loaded: Bool) {
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
        userDefaults.setObject(loadedPluginNames, forKey: "LoadedPlugins")
    }

    public func updatePlugins() -> Observable<Void> {
        var scripts = storedPlugins
        scripts.append(mainScript)
        scripts.append(positionScript)
        return scripts.toObservable().flatMap {
            script -> Observable<(String, Script)> in
            guard let url = script.updateURL else {
                return Observable<(String, Script)>.just(("", script))
            }
            return Alamofire.request(.GET, url).rx_string().map {
                string -> (String, Script) in
                return (string, script)
            }
        }.flatMap {
            string, script -> Observable<Void> in
            let attribute = Script.getJSAttributes(string)
            var shouldDownload = false
            if let newVersion = attribute["version"] {
                if let oldVersion = script.version {
                    if newVersion.compare(oldVersion, options: .NumericSearch) != .OrderedDescending {
                        shouldDownload = true
                    }
                } else {
                    shouldDownload = true
                }
            }
            if shouldDownload {
                return Alamofire.request(.GET, attribute["downloadURL"]!).rx_string().map {
                    string in
                    do {
                        var prefix: NSURL
                        if script.category == "Core" {
                            prefix = self.libraryScriptsPath
                        } else {
                            prefix = self.libraryPluginsPath
                        }
                        try string.writeToURL(prefix.URLByAppendingPathComponent(script.fileName), atomically: true, encoding: NSUTF8StringEncoding)
                    } catch let e as NSError {
                        print(e)
                    }
                }
            }
            return Observable<Void>.just(Void())

        }
    }
    
    public func syncDocumentAndContainer() {
        let temp = (try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentPath, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)) ?? []
        for url in temp {
            if url.lastPathComponent! == "com.google.iid-keypair.plist" {
                continue
            }
            let containerFileURL = userScriptsPath.URLByAppendingPathComponent(url.lastPathComponent!)
            if !NSFileManager.defaultManager().fileExistsAtPath(containerFileURL.path!) {
                try? NSFileManager.defaultManager().copyItemAtURL(url, toURL: containerFileURL)
                try? NSFileManager.defaultManager().removeItemAtURL(url)
            }
        }

    }
    
    func directoryDidChange(folderWatcher: DirectoryWatcher) {
        if folderWatcher == documentWatcher {
            syncDocumentAndContainer()
        } else if folderWatcher == containerWatcher {
            self.loadAllPlugins()
            self.loadUserMainScript()
            NSNotificationCenter.defaultCenter().postNotificationName(ScriptsUpdatedNotification, object: nil)
        }
    }
}
