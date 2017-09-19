//
//  Script.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

open class Script: NSObject {
    open var fileName: String
    open var version: String?
    open var name: String?
    open var category: String
    open var scriptDescription: String?
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

    init(atFilePath filePath: URL) throws {
        self.fileContent = try String(contentsOf: filePath)
        let attributes = Script.getJSAttributes(fileContent)
        self.version = attributes["version"]
        self.updateURL = attributes["updateURL"]
        self.downloadURL = attributes["downloadURL"]
        self.name = attributes["name"]
        self.category = attributes["category"] ?? "Undefined"
        self.scriptDescription = attributes["description"]
        self.filePath = filePath.resolvingSymlinksInPath()
        self.fileName = filePath.lastPathComponent
        super.init()
    }

    static func getJSAttributes(_ fileContent: String) -> [String: String] {
        var attributes = [String: String]()

        do {
            guard let range1 = fileContent.range(of: "==UserScript==") else {
                return attributes
            }
            guard let range2 = fileContent.range(of: "==/UserScript==") else {
                return attributes
            }
            var e: NSRegularExpression
            e = try NSRegularExpression(pattern: "//.*?@([^\\s]*)\\s*(.*)")
            let header = fileContent.substring(with: Range<String.Index>(range1.upperBound..<range2.lowerBound))
            for line in header.components(separatedBy: "\n") {
                let search = e.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
                if (search.count > 0) {
                    var start = line.characters.index(line.startIndex, offsetBy: search[0].rangeAt(1).location)
                    var end = line.characters.index(start, offsetBy: search[0].rangeAt(1).length - 1)
                    let rangeId = line[start...end]
                    start = line.characters.index(line.startIndex, offsetBy: search[0].rangeAt(2).location)
                    end = line.characters.index(start, offsetBy: search[0].rangeAt(2).length - 1)
                    let rangeDetail = line[start...end]
                    attributes[rangeId] = rangeDetail
                }
            }
        } catch _ as NSError {

        }
        return attributes
    }

}
