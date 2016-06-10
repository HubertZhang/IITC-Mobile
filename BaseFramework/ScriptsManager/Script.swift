//
//  Script.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class Script: NSObject {
    var fileName: String
    var version: String?
    var name: String?
    var category: String
    var scriptDescription: String?
    var filePath: NSURL
    var downloadURL: String?
    var updateURL: String?
    var fileContent: String

    init(coreJS filePath: NSURL, withName name: String) throws {
        self.fileContent = try String(contentsOfURL: filePath)
        self.name = name
        self.filePath = filePath;
        self.fileName = filePath.lastPathComponent!
        self.category = "Core"
        super.init()
    }

    init(atFilePath filePath: NSURL) throws {
        self.fileContent = try String(contentsOfURL: filePath)
        let attributes = Script.getJSAttributes(fileContent)
        self.version = attributes["version"];
        self.updateURL = attributes["updateURL"];
        self.downloadURL = attributes["downloadURL"];
        self.name = attributes["name"];
        self.category = attributes["category"] ?? "Undefined"
        self.scriptDescription = attributes["description"];
        self.filePath = filePath;
        self.fileName = filePath.lastPathComponent!
        super.init()
    }

    static func getJSAttributes(fileContent: String) -> Dictionary<String, String> {
        var attributes = Dictionary<String, String>()

        do {
            guard let range1 = fileContent.rangeOfString("==UserScript==") else {
                return attributes
            }
            guard let range2 = fileContent.rangeOfString("==/UserScript==") else {
                return attributes
            }
            var e: NSRegularExpression
            e = try NSRegularExpression(pattern: "//.*?@([^\\s]*)\\s*(.*)", options: NSRegularExpressionOptions(rawValue: 0))
            let header = fileContent.substringWithRange(Range<String.Index>(range1.endIndex.successor() ..< range2.startIndex))
            for line in header.componentsSeparatedByString("\n") {
//                print(line)
                let search = e.matchesInString(line, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, (line as NSString).length))
                if (search.count > 0) {
//                    print(search[0].rangeAtIndex(1))
//                    print(search[0].rangeAtIndex(2))
                    var start = line.startIndex.advancedBy(search[0].rangeAtIndex(1).location)
                    var end = start.advancedBy(search[0].rangeAtIndex(1).length - 1)
                    let rangeId = line[start ... end]
                    start = line.startIndex.advancedBy(search[0].rangeAtIndex(2).location)
                    end = start.advancedBy(search[0].rangeAtIndex(2).length - 1)
                    let rangeDetail = line[start ... end]
                    attributes[rangeId] = rangeDetail
                }
            }
        } catch _ as NSError {

        }

//        print(attributes)
        return attributes
    }

}
