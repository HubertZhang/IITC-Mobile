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

public enum IITCVersion: String {
    case originalRelease = "release"
    case originalTest = "test"
    case ce = "ce"
    case ceTest = "ce-test"
}

open class ScriptsManager: NSObject, DirectoryWatcherDelegate {
    public var currentVersion: IITCVersion

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

    var userDefaults = UserDefaults(suiteName: ContainerIdentifier)!

    let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    let bundleScriptPath = Bundle(for: ScriptsManager.classForCoder()).resourceURL!.appendingPathComponent("scripts", isDirectory: true)
    let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ContainerIdentifier)!

    public let sharedScriptsPath: URL
    public let userScriptsPath: URL

    private var defaultObservation: NSKeyValueObservation?
    override init() {
        sharedScriptsPath = documentPath.appendingPathComponent("embedded", isDirectory: true)
        userScriptsPath = documentPath.appendingPathComponent("userScripts", isDirectory: true)
        try? FileManager.default.createDirectory(at: userScriptsPath, withIntermediateDirectories: true, attributes: nil)

        currentVersion = IITCVersion(rawValue: userDefaults.pref_iitc_version ?? "release") ?? .originalRelease

        loadedPluginNames = userDefaults.array(forKey: "LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)

        super.init()

        checkUpgrade()

        defaultObservation = userDefaults.observe(\.pref_iitc_version) { (defaults, _) in
            guard let v = IITCVersion(rawValue: defaults.pref_iitc_version ?? "release") else {
                return
            }
            self.switchIITCVersion(version: v)
        }

        documentWatcher = DirectoryWatcher(userScriptsPath, delegate: self)

        hookScript = try! Script(coreJS: bundleScriptPath.appendingPathComponent("ios-hooks.js"), withName: "hook")
        hookScript.fileContent = String(format: hookScript.fileContent, VersionTool.default.currentVersion, Int(VersionTool.default.currentBuild) ?? 0)

        reloadScripts()
    }

    func checkUpgrade() {
        let copied = FileManager.default.fileExists(atPath: sharedScriptsPath.path)

        let oldVersion = userDefaults.string(forKey: "Version") ?? "0.0.0"
        let oldBuild = userDefaults.string(forKey: "BuildVersion") ?? "0"
        var upgraded = VersionTool.default.isVersionUpdated(from: oldVersion) || !VersionTool.default.isSameBuild(with: oldBuild)
        #if DEBUG
        upgraded = true
        #endif
        if !copied || upgraded {
            try? FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.removeItem(at: sharedScriptsPath)
            try? FileManager.default.copyItem(at: bundleScriptPath, to: sharedScriptsPath)
            userDefaults.set(VersionTool.default.currentVersion, forKey: "Version")
            userDefaults.set(VersionTool.default.currentBuild, forKey: "BuildVersion")
        }
        migrateFromContainer()
    }

    func migrateFromContainer() {
        let oldPath = containerPath.appendingPathComponent("userScripts", isDirectory: true)
        if FileManager.default.fileExists(atPath: oldPath.path) {
            guard let directoryContents = try? FileManager.default.contentsOfDirectory(at: oldPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
                return
            }
            for pluginPath in directoryContents {
                do {
                    try FileManager.default.copyItem(at: pluginPath, to: userScriptsPath.appendingPathComponent(pluginPath.lastPathComponent))
                } catch {
                    continue
                }
            }
            try? FileManager.default.removeItem(at: oldPath)
        }
    }

    open func reloadScripts() {
        loadMainScripts()
        loadAllPlugins()
        NotificationCenter.default.post(name: ScriptsUpdatedNotification, object: nil)
        synchronizeDocumentToContainer()
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
        result.append(hookScript)
        result.append(mainScript)
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

    open func updatePlugin(script: Script) -> (Observable<Void>, Progress) {
        let progress = Progress.init(totalUnitCount: 20)
        let observable = Observable.just(1).flatMap { (_) -> Observable<(String?)> in
            guard let updateURL = script.updateURL else {
                progress.completedUnitCount = 10
                return Observable.just(nil)
            }
            let request = Alamofire.request(updateURL)
            progress.addChild(request.progress, withPendingUnitCount: 10)
            return request.rx.string().map { metaData -> String? in
                let attribute = Script.getJSAttributes(metaData)
                guard let downloadURL = attribute["downloadURL"]?.first else {
                    return nil
                }
                guard let newVersion = attribute["version"]?.first, let oldVersion = script.version else {
                    return nil
                }
                if newVersion.compare(oldVersion, options: .numeric) != .orderedDescending {
                    return nil
                }
                return downloadURL
            }
        }.flatMap { (downloadURL) -> Observable<Void> in
            guard let downloadURL = downloadURL else {
                progress.completedUnitCount += 10
                return Observable.just(Void())
            }
            let request = Alamofire.request(downloadURL)
            progress.addChild(request.progress, withPendingUnitCount: 10)
            return request.rx.data().map { (data) in
                var path: URL
                if script.isUserScript {
                    path = self.userScriptsPath.appendingPathComponent(script.fileName)
                } else {
                    path = script.filePath
                }
                try data.write(to: path)
            }
        }

        return (observable, progress)
    }

    open func updatePlugins() -> (Observable<Void>, Progress) {
        var scripts = storedPlugins
        scripts.append(mainScript)
        scripts.append(positionScript)
        let progress = Progress(totalUnitCount: Int64(scripts.count * 20))
        return (Observable.from(scripts).flatMap {
            script -> Observable<Void> in
            let (o, p) = self.updatePlugin(script: script)
            progress.addChild(p, withPendingUnitCount: 20)
            return o
        }, progress)
    }

    open func synchronizeDocumentToContainer() {
        let mainAppInContainer = containerPath.appendingPathComponent("main", isDirectory: true)
        try? FileManager.default.removeItem(at: mainAppInContainer)
        try? FileManager.default.copyItem(at: userScriptsPath, to: mainAppInContainer)
    }

    open func synchronizeExtensionFolder() {
        let extensionFolder = containerPath.appendingPathComponent("extension", isDirectory: true)
        let temp = (try? FileManager.default.contentsOfDirectory(at: extensionFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
        for url in temp {
            let containerFileURL = userScriptsPath.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: containerFileURL.path) {
                do {
                    let oldAttr = try FileManager.default.attributesOfItem(atPath: self.containerPath.path)
                    let newAttr = try FileManager.default.attributesOfItem(atPath: url.path)
                    guard let oldDate = oldAttr[.modificationDate] as? Date, let newDate = newAttr[.modificationDate] as? Date else {
                        continue
                    }
                    if newDate.compare(oldDate) == .orderedDescending {
                        try FileManager.default.removeItem(at: containerFileURL)
                        try FileManager.default.copyItem(at: url, to: containerFileURL)
                    }
                } catch {

                }
            }
            try? FileManager.default.removeItem(at: url)
        }
    }

    func directoryDidChange(_ folderWatcher: DirectoryWatcher) {
        if folderWatcher == documentWatcher {
            self.reloadScripts()
        }
    }

    open func reloadSettings() {
        loadedPluginNames = userDefaults.array(forKey: "LoadedPlugins") as? [String] ?? [String]()
        loadedPlugins = Set<String>(loadedPluginNames)
    }

    open func switchIITCVersion(version: IITCVersion) {
        self.currentVersion = version
        self.reloadScripts()
    }
}
