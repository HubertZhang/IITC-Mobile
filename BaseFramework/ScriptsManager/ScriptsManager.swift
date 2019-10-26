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

extension UserDefaults {
    @objc dynamic var pref_iitc_version: String? {
        return string(forKey: "pref_iitc_version")
    }
}

public let ScriptsUpdatedNotification = Notification.Name(rawValue: "ScriptsUpdatedNotification")
public let ContainerIdentifier: String = "group.com.vuryleo.iitc"

open class ScriptsManager: NSObject, DirectoryWatcherDelegate {
    public enum Version: String {
        case originalRelease = "release"
        case originalTest = "test"
        case ce = "ce"
    }

    public var currentVersion: Version

    public static let sharedInstance = ScriptsManager()

    open var storedPlugins = [Script]()
    var loadedPluginNames: [String]
    open var loadedPlugins: Set<String>

    var hookScript: Script!
    open var mainScript: Script!
    open var positionScript: Script!

    var iitcRootPath: URL {
        return sharedScriptsPath.appendingPathComponent(currentVersion.rawValue, isDirectory: true)
    }
    var iitcPluginPath: URL {
        return iitcRootPath.appendingPathComponent("plugins", isDirectory: true)
    }

    var documentWatcher: DirectoryWatcher?
    var containerWatcher: DirectoryWatcher?

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    let bundleScriptPath = Bundle(for: ScriptsManager.classForCoder()).resourceURL!.appendingPathComponent("scripts", isDirectory: true)
    let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!
    let sharedScriptsPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!.appendingPathComponent("scripts", isDirectory: true)
    public var userScriptsPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!.appendingPathComponent("userScripts", isDirectory: true)

    private var defaultObservation: NSKeyValueObservation?
    override init() {
        try? FileManager.default.createDirectory(at: userScriptsPath, withIntermediateDirectories: true, attributes: nil)

        currentVersion = ScriptsManager.Version(rawValue: userDefaults.pref_iitc_version ?? "release") ?? .originalRelease

        loadedPluginNames = userDefaults.array(forKey: "LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)

        super.init()

        checkUpgrade()

        defaultObservation = userDefaults.observe(\.pref_iitc_version) { (defaults, _) in
            guard let v = ScriptsManager.Version(rawValue: defaults.pref_iitc_version ?? "release") else {
                return
            }
            self.switchIITCVersion(version: v)
        }

        syncDocumentAndContainer()
        documentWatcher = DirectoryWatcher(documentPath, delegate: self)
        containerWatcher = DirectoryWatcher(userScriptsPath, delegate: self)

        hookScript = try! Script(coreJS: bundleScriptPath.appendingPathComponent("ios-hooks.js"), withName: "hook")
        hookScript.fileContent = String(format: hookScript.fileContent, VersionTool.default.currentVersion, Int(VersionTool.default.currentBuild) ?? 0)

        reloadScripts()
    }

    func checkUpgrade() {
        let sharedScriptsPath = containerPath.appendingPathComponent("scripts", isDirectory: true)
        let copied = FileManager.default.fileExists(atPath: sharedScriptsPath.path)

        let oldVersion = userDefaults.string(forKey: "Version") ?? "0.0.0"
        let oldBuild = userDefaults.string(forKey: "BuildVersion") ?? "0"
        var upgraded = VersionTool.default.isVersionUpdated(from: oldVersion) || !VersionTool.default.isSameBuild(with: oldBuild)
        #if DEBUG
        upgraded = true
        #endif
        if !copied || upgraded {
            try? FileManager.default.createDirectory(at: containerPath, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.removeItem(at: sharedScriptsPath)
            try? FileManager.default.copyItem(at: bundleScriptPath, to: sharedScriptsPath)
            userDefaults.set(VersionTool.default.currentVersion, forKey: "Version")
            userDefaults.set(VersionTool.default.currentBuild, forKey: "BuildVersion")
        }
    }

    open func reloadScripts() {
        loadMainScripts()
        loadAllPlugins()
    }

    func loadAllPlugins() {
        self.storedPlugins = loadPluginInDirectory(iitcPluginPath)
        for plugin in loadPluginInDirectory(userScriptsPath) {
            plugin.isUserScript = true
            let index = storedPlugins.firstIndex {
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

    func loadMainScripts() {
        do {
            mainScript = try Script(atFilePath: iitcRootPath.appendingPathComponent("total-conversion-build.user.js"))
            mainScript.category = "Core"
            positionScript = try Script(coreJS: iitcRootPath.appendingPathComponent("user-location.user.js"), withName: "position")
        } catch {

        }
        loadUserMainScript()
    }

    func loadUserMainScript() {
        let userURL = userScriptsPath.appendingPathComponent("total-conversion-build.user.js")
        if FileManager.default.fileExists(atPath: userURL.path) {
            do {
                mainScript = try Script(atFilePath: userURL)
                mainScript.category = "Core"
                mainScript.isUserScript = true
            } catch {

            }
        }
        let userLocationURL = userScriptsPath.appendingPathComponent("user-location.user.js")
        if FileManager.default.fileExists(atPath: userLocationURL.path) {
            do {
                positionScript = try Script(atFilePath: userLocationURL)
                positionScript.category = "Core"
                positionScript.isUserScript = true
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
            if pluginPath.lastPathComponent == "user-location.user.js" {
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
            let index = storedPlugins.firstIndex {
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
        let index = loadedPluginNames.firstIndex {
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
            guard let downloadURL = attribute["downloadURL"]?.first else {
                return Observable<Void>.just(Void())
            }
            guard let newVersion = attribute["version"]?.first, let oldVersion = script.version else {
                return Observable<Void>.just(Void())
            }
            if newVersion.compare(oldVersion, options: .numeric) != .orderedDescending {
                return Observable<Void>.just(Void())
            }
            return Alamofire.request(downloadURL).rx.string().map {
                string in
                var path: URL
                if script.isUserScript {
                    path = self.userScriptsPath.appendingPathComponent(script.fileName)
                } else {
                    path = script.filePath
                }

                try string.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            }
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
            if FileManager.default.fileExists(atPath: containerFileURL.path) {
                try? FileManager.default.removeItem(at: containerFileURL)
            }
            try? FileManager.default.copyItem(at: url, to: containerFileURL)
            try? FileManager.default.removeItem(at: url)
        }

    }

    func directoryDidChange(_ folderWatcher: DirectoryWatcher) {
        if folderWatcher == documentWatcher {
            syncDocumentAndContainer()
        } else if folderWatcher == containerWatcher {
            self.loadMainScripts()
            self.loadAllPlugins()
            NotificationCenter.default.post(name: ScriptsUpdatedNotification, object: nil)
        }
    }

    open func reloadSettings() {
        loadedPluginNames = userDefaults.array(forKey: "LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)
    }

    open func switchIITCVersion(version: Version) {
        self.currentVersion = version
        loadMainScripts()
        loadAllPlugins()
    }
}
