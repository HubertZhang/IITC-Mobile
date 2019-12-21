//
//  Script.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

open class Script: NSObject {
    @objc open var fileName: String
    @objc open var version: String?
    @objc open var name: String?
    @objc open var category: String
    @objc open var scriptDescription: String?
    open var filePath: URL
    open var downloadURL: String?
    open var updateURL: String?
    open var fileContent: String
    open var isUserScript: Bool = false

    init(coreJS filePath: URL, withName name: String) throws {
        self.fileContent = try String(contentsOf: filePath)
        self.name = name
        self.filePath = filePath.resolvingSymlinksInPath()
        self.fileName = filePath.lastPathComponent
        self.category = "Core"
        super.init()
    }

    static func generateGMInfo(_ attributes: [String: [String]]) -> String {
        var temp: [String: String] = [:]
        for (key, value) in attributes {
            temp[key] = value.joined(separator: ",")
        }
        let pluginInfo = ["script": temp]
        return String(data: try! JSONEncoder().encode(pluginInfo), encoding: .utf8)!
    }

    public init(atFilePath filePath: URL) throws {
        self.fileContent = try String(contentsOf: filePath)
        let attributes = Script.getJSAttributes(fileContent)
        let start = "var GM_info = \(Script.generateGMInfo(attributes));\n"
        self.fileContent = start + self.fileContent
        self.version = attributes["version"]?.first
        self.updateURL = attributes["updateURL"]?.first
        self.downloadURL = attributes["downloadURL"]?.first
        self.name = attributes["name"]?.first
        self.category = attributes["category"]?.first ?? "Undefined"
        self.scriptDescription = attributes["description"]?.first
        self.filePath = filePath.resolvingSymlinksInPath()
        self.fileName = filePath.lastPathComponent
        super.init()
    }

    static func getJSAttributes(_ fileContent: String) -> [String: [String]] {
        var attributes = [String: [String]]()

        guard let range1 = fileContent.range(of: "==UserScript==") else {
            return attributes
        }
        guard let range2 = fileContent.range(of: "==/UserScript==") else {
            return attributes
        }

        let header = fileContent[range1.upperBound..<range2.lowerBound]
        for line in header.components(separatedBy: "\n") {
            var keyNS: NSString?, valueNS: NSString?
            let scanner = Scanner(string: line)

            // Skip to "@"
            scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "@"), into: nil)

            // Read key until whitespace
            if scanner.isAtEnd {
                continue
            }
            scanner.scanString("@", into: nil)
            scanner.scanUpToCharacters(from: .whitespaces, into: &keyNS)

            // Read value until "\r" or "\n"
            if scanner.isAtEnd {
                continue
            }
            scanner.scanUpToCharacters(from: .newlines, into: &valueNS)

            guard let key = keyNS as String?, let value = valueNS as String? else {
                continue
            }
            if attributes[key] == nil {
                attributes[key] = [value]
            } else {
                attributes[key]?.append(value)
            }
        }
        return attributes
    }

}
