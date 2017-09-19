//
//  DirectoryWatcher.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/9.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

protocol DirectoryWatcherDelegate: class {
    func directoryDidChange(_ folderWatcher: DirectoryWatcher)
}

class DirectoryWatcher: NSObject {
    var path: URL
    var source: DispatchSourceFileSystemObject!
    weak var delegate: DirectoryWatcherDelegate?

    init(_ dirPath: URL, delegate: DirectoryWatcherDelegate) {
        path = dirPath
        self.delegate = delegate
        super.init()
        self.o()
    }

    func o() {
        let observerQueue = DispatchQueue(label: "com.vuryleo.iitcmobile.directorywatch", attributes: DispatchQueue.Attributes.concurrent)
        let fileDescr = open((path as NSURL).fileSystemRepresentation, O_EVTONLY)
        // observe file system events for particular path - you can pass here Documents directory path
        //observer queue is my private dispatch_queue_t object
        if fileDescr < 0 {
            return
        }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescr, eventMask: [.attrib, .write, .link, .extend], queue: observerQueue)
        // create dispatch_source object to observe vnode events
        source.setRegistrationHandler(handler: {
            //event handler is called each time file system event of selected type (DISPATCH_VNODE_*) has occurred
            self.source.setEventHandler(handler: {
                self.delegate?.directoryDidChange(self)
//                //obtain flags
//                let flags = self.source.data
//                print("%lu", flags)
//                //flag is set to DISPATCH_VNODE_WRITE every time data is appended to file
//                if (flags.contains(.write)) {
//                    print("DISPATCH_VNODE_WRITE")
//                    let dict = try! FileManager.default.attributesOfItem(atPath: self.path.path)
//                    let size = (dict[FileAttributeKey.size]! as AnyObject).floatValue
//                    print("%f", size)
//                }
//                //this flag is passed when file is completely written.
//                if (flags.contains(.attrib)) {
//                    print("DISPATCH_VNODE_ATTRIB")
//                    self.source.cancel()
//                }
//                if (flags.contains(.link)) {
//                    print("DISPATCH_VNODE_LINK")
//                }
//                if (flags.contains(.extend)) {
//                    print("DISPATCH_VNODE_EXTEND")
//                }
//                print("file = %@", self.path)
//                print("\n\n")
            })

            self.source.setCancelHandler(handler: {
                close(fileDescr)
            })
        })
//        we have to resume dispatch_objects
        source.resume()
    }
}
