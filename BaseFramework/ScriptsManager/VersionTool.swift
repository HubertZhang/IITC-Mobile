//
//  VersionManager.swift
//  BaseFramework
//
//  Created by Hubert Zhang on 2019/8/8.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

class VersionTool: NSObject {
    public static let `default` = VersionTool()

    public let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    public let currentBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""

    open func isSameVersion(with oldVersion: String) -> Bool {
        return self.currentVersion.compare(oldVersion, options: .numeric) == .orderedSame
    }

    open func isVersionUpdated(from oldVersion: String) -> Bool {
        return self.currentVersion.compare(oldVersion, options: .numeric) == .orderedDescending
    }

    open func isSameBuild(with oldBuild: String) -> Bool {
        return self.currentBuild.compare(oldBuild, options: .numeric) == .orderedSame
    }

    open func isBuildUpdated(from oldBuild: String) -> Bool {
        return self.currentBuild.compare(oldBuild, options: .numeric) == .orderedDescending
    }
}
