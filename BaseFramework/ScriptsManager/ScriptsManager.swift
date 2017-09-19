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

public let ScriptsUpdatedNotification = Notification.Name(rawValue: "ScriptsUpdatedNotification")
public let ContainerIdentifier: String = "group.com.vuryleo.iitc"

open class ScriptsManager: NSObject, DirectoryWatcherDelegate {
    open static let sharedInstance = ScriptsManager()

    open var storedPlugins = [Script]()
    var loadedPluginNames: [String]
    open var loadedPlugins: Set<String>

    open var mainScript: Script
    var hookScript: Script
    open var positionScript: Script

    var libraryScriptsPath: URL
    var libraryPluginsPath: URL
    open var userScriptsPath: URL
    var documentPath: URL

    var documentWatcher: DirectoryWatcher?
    var containerWatcher: DirectoryWatcher?

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    override init() {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
        libraryScriptsPath = containerPath.appendingPathComponent("scripts", isDirectory: true)
        libraryPluginsPath = libraryScriptsPath.appendingPathComponent("plugins", isDirectory: true)
        userScriptsPath = containerPath.appendingPathComponent("userScripts", isDirectory: true)
        try? FileManager.default.createDirectory(at: userScriptsPath, withIntermediateDirectories: true, attributes: nil)
        documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let mainScriptPath = libraryScriptsPath.appendingPathComponent("total-conversion-build.user.js")
        let copied = FileManager.default.fileExists(atPath: mainScriptPath.path)
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let oldVersion = userDefaults.string(forKey: "Version") ?? "0.0.0"
        let upgraded = currentVersion.compare(oldVersion, options: .numeric) != .orderedSame
        if !copied || upgraded {
            try? FileManager.default.createDirectory(at: containerPath, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.removeItem(at: libraryScriptsPath)
            try? FileManager.default.copyItem(at: Bundle(for: ScriptsManager.classForCoder()).resourceURL!.appendingPathComponent("scripts", isDirectory: true), to: libraryScriptsPath)
            userDefaults.set(currentVersion, forKey: "Version")
        }
        let currentBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let buildNumber = Int(currentBuild) ?? 0
        do {
            mainScript = try Script(atFilePath: libraryScriptsPath.appendingPathComponent("total-conversion-build.user.js"))
            mainScript.category = "Core"
            hookScript = try Script(coreJS: libraryScriptsPath.appendingPathComponent("ios-hooks.js"), withName: "hook")
            hookScript.fileContent = String(format: hookScript.fileContent, currentVersion, buildNumber)
            positionScript = try Script(coreJS: libraryScriptsPath.appendingPathComponent("user-location.user.js"), withName: "position")
        } catch {
            exit(-1)
        }
        loadedPluginNames = userDefaults.array(forKey: "LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)

        super.init()
//        print(userScriptsPath.absoluteString)
        syncDocumentAndContainer()
        documentWatcher = DirectoryWatcher(documentPath, delegate: self)
        containerWatcher = DirectoryWatcher(userScriptsPath, delegate: self)

        loadUserMainScript()
        loadAllPlugins()

    }

    open func loadAllPlugins() {
        self.storedPlugins = loadPluginInDirectory(libraryPluginsPath)
        for plugin in loadPluginInDirectory(userScriptsPath) {
            plugin.isUserScript = true
            let index = storedPlugins.index {
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

    open func loadUserMainScript() {
        let userURL = userScriptsPath.appendingPathComponent("total-conversion-build.user.js")
        if FileManager.default.fileExists(atPath: userURL.path) {
            do {
                mainScript = try Script(atFilePath: userURL)
                mainScript.category = "Core"
                mainScript.isUserScript = true
            } catch {

            }
        }
    }

    func loadPluginInDirectory(_ url: URL) -> [Script] {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        guard let directoryContents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return []
        }
        var result = [Script]()
        for pluginPath in directoryContents {
            if !pluginPath.path.hasSuffix(".js") {
                continue
            }
            if pluginPath.path.hasSuffix(".meta.js") {
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

    open func getLoadedScripts() -> [Script] {
        var result = [Script]()
        result.append(mainScript)
        result.append(hookScript)
        for name in loadedPluginNames {
            let index = storedPlugins.index {
                plugin -> Bool in
                return plugin.fileName == name
            }
            if index != nil {
                if name == "canvas-render.user.js" {
                    result.insert(storedPlugins[index!], at: 0)
                } else {
                    result.append(storedPlugins[index!])
                }
            }
        }
        return result
    }

    open func setPlugin(_ script: Script, loaded: Bool) {
        let index = loadedPluginNames.index {
            plugin -> Bool in
            return plugin == script.fileName
        }
        if index != nil && !loaded {
            loadedPluginNames.remove(at: index!)
        } else if index == nil && loaded {
            loadedPluginNames.append(script.fileName)
        }
        loadedPlugins = Set<String>(loadedPluginNames)
        userDefaults.set(loadedPluginNames, forKey: "LoadedPlugins")
    }

    open func updatePlugins() -> Observable<Void> {
        var scripts = storedPlugins
        scripts.append(mainScript)
        scripts.append(positionScript)
        return Observable.from(scripts).flatMap {
            script -> Observable<(String, Script)> in
            guard let url = script.updateURL else {
                return Observable<(String, Script)>.just(("", script))
            }
            return Alamofire.request(url).rx.string().map {
                string -> (String, Script) in
                return (string, script)
            }
        }.flatMap {
            string, script -> Observable<Void> in
            let attribute = Script.getJSAttributes(string)
            var shouldDownload = false
            if let newVersion = attribute["version"] {
                if let oldVersion = script.version {
                    if newVersion.compare(oldVersion, options: .numeric) != .orderedDescending {
                        shouldDownload = true
                    }
                } else {
                    shouldDownload = true
                }
            }
            if shouldDownload {
                return Alamofire.request(attribute["downloadURL"]!).rx.string().map {
                    string in
                    do {
                        var pathPrefix: URL
                        if script.category == "Core" {
                            pathPrefix = self.libraryScriptsPath
                        } else {
                            pathPrefix = self.libraryPluginsPath
                        }

                        pathPrefix.appendPathComponent(script.fileName)
                        try string.write(to: pathPrefix, atomically: true, encoding: String.Encoding.utf8)
                    } catch let e as NSError {
                        print(e)
                    }
                }
            }

            return Observable<Void>.just(Void())

        }
    }

    open func syncDocumentAndContainer() {
        let temp = (try? FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
        for url in temp {
            if url.lastPathComponent == "com.google.iid-keypair.plist" {
                continue
            }
            if url.lastPathComponent == "Inbox" {
                continue
            }
            let containerFileURL = userScriptsPath.appendingPathComponent(url.lastPathComponent)
            if !FileManager.default.fileExists(atPath: containerFileURL.path) {
                try? FileManager.default.copyItem(at: url, to: containerFileURL)
                try? FileManager.default.removeItem(at: url)
            }
        }

    }

    func directoryDidChange(_ folderWatcher: DirectoryWatcher) {
        if folderWatcher == documentWatcher {
            syncDocumentAndContainer()
        } else if folderWatcher == containerWatcher {
            self.loadAllPlugins()
            self.loadUserMainScript()
            NotificationCenter.default.post(name: ScriptsUpdatedNotification, object: nil)
        }
    }

}
