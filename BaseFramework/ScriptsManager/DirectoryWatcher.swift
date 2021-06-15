//
//  DirectoryWatcher.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/9.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

protocol DirectoryWatcherDelegate: AnyObject {
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
        // observer queue is my private dispatch_queue_t object
        if fileDescr < 0 {
            return
        }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescr, eventMask: [.attrib, .write, .link, .extend], queue: observerQueue)
        source.setEventHandler {
            self.delegate?.directoryDidChange(self)
        }

        source.setCancelHandler {
            close(fileDescr)
        }
//        we have to resume dispatch_objects
        source.resume()
    }
}
