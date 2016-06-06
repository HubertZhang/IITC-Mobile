//
//  Script.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/6.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

class Script: NSObject {
    var fileName : String
    var version : String?
    var name : String?
    var category : String?
    var scriptDescription : String?
    var filePath : NSURL
    var downloadURL : String?
    var updateURL : String?
    lazy var fileContent : String = {
        return try! String(contentsOfURL:self.filePath, encoding:  NSUTF8StringEncoding)
    }()
    
    init(atFilePath filePath:NSURL) {
        let fileContent = String(fileContent:filePath, encoding:  NSUTF8StringEncoding)
        let attributes = Script.getJSAttributes(fileContent)
        self.version = attributes["version"];
        self.updateURL = attributes["updateURL"];
        self.downloadURL = attributes["downloadURL"];
        self.name = attributes["name"];
        self.category = attributes["category"];
        if (self.category == nil) {
            self.category = "Undefined";
        }
        self.scriptDescription = attributes["description"];
        self.filePath = filePath;
        self.fileName = filePath.lastPathComponent!
        super.init()
    }
    
    static func getJSAttributes(fileContent:String) -> Dictionary<String, String> {
        var attributes = Dictionary<String, String>()
        
        do {
            let range1 = fileContent.rangeOfString("==UserScript==")
            let range2 = fileContent.rangeOfString("==/UserScript==")
            
            var e:NSRegularExpression
            e = try NSRegularExpression(pattern: "//.*?@([^\\s]*)\\s*(.*)", options: NSRegularExpressionOptions(rawValue: 0))
            let header = fileContent.substringWithRange(Range<String.Index>(start: (range1?.endIndex)!.successor(), end: (range2?.startIndex)!))
            for line in header.componentsSeparatedByString("\n") {
                print(line)
                let search = e.matchesInString(line, options: NSMatchingOptions(rawValue: 0), range:NSMakeRange(0, line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
                if (search.count>0) {
                    print(search[0].rangeAtIndex(1))
                    print(search[0].rangeAtIndex(2))
                    var start = line.startIndex.advancedBy(search[0].rangeAtIndex(1).location )
                    var end = start.advancedBy(search[0].rangeAtIndex(1).length-1)
                    let rangeId = line[start ... end]
                    start = line.startIndex.advancedBy(search[0].rangeAtIndex(2).location)
                    end = start.advancedBy(search[0].rangeAtIndex(2).length-1)
                    let rangeDetail = line[start ... end]
                    attributes[rangeId]=rangeDetail
                }
            }
        } catch _ as NSError {
            
        }
        
        print(attributes)
        return attributes
    }

}
