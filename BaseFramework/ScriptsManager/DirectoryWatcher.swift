//
//  DirectoryWatcher.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/9.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

protocol DirectoryWatcherDelegate {
    func directoryDidChange(_ folderWatcher: DirectoryWatcher)
}

class DirectoryWatcher: NSObject {
    var path :URL
    var source: DispatchSource!
    var delegate: DirectoryWatcherDelegate
    init(_ dirPath:URL, delegate:DirectoryWatcherDelegate) {
        path = dirPath
        self.delegate = delegate
        super.init()
        self.o()
    }
    
    func o() {
        let observerQueue = DispatchQueue(label: "aaa", attributes: DispatchQueue.Attributes.concurrent)
        let fileDescr = open((path as NSURL).fileSystemRepresentation, O_EVTONLY);// observe file system events for particular path - you can pass here Documents directory path
        //observer queue is my private dispatch_queue_t object
        if fileDescr < 0 {
            return
        }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescr, eventMask: [.attrib , .write , .link , .extend], queue: observerQueue) /*Migrator FIXME: Use DispatchSourceFileSystemObject to avoid the cast*/ as! DispatchSource;// create dispatch_source object to observe vnode events
        source.setRegistrationHandler(handler: {
//            print("registered for observation");
            //event handler is called each time file system event of selected type (DISPATCH_VNODE_*) has occurred
            self.source.setEventHandler(handler: {

//                let flags = dispatch_source_get_data(self.source);//obtain flags
//                print("%lu",flags);
                self.delegate.directoryDidChange(self)
//                if(flags & DISPATCH_VNODE_WRITE != 0)//flag is set to DISPATCH_VNODE_WRITE every time data is appended to file
//                {
//                    print("DISPATCH_VNODE_WRITE");
//                    let dict = try! NSFileManager.defaultManager().attributesOfItemAtPath(self.path.path!);
//                    let size = dict[NSFileSize]!.floatValue
//                    print("%f",size);
//                }
//                if(flags & DISPATCH_VNODE_ATTRIB != 0)//this flag is passed when file is completely written.
//                {
//                    print("DISPATCH_VNODE_ATTRIB");
//                    dispatch_source_cancel(source);
//                }
//                if(flags & DISPATCH_VNODE_LINK != 0)
//                {
//                    print("DISPATCH_VNODE_LINK");
//                }
//                if(flags & DISPATCH_VNODE_EXTEND != 0)
//                {
//                    print("DISPATCH_VNODE_EXTEND");
//                }
//                print("file = %@",self.path);
//                print("\n\n");
                });
            
            self.source.setCancelHandler(handler: {
                close(fileDescr);
                });
            });
//
//        //we have to resume dispatch_objects
        source.resume();
//
//        return source;
    }
}
