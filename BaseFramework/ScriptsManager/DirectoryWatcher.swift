//
//  DirectoryWatcher.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 16/6/9.
//  Copyright © 2016年 IITC. All rights reserved.
//

import UIKit

protocol DirectoryWatcherDelegate {
    func directoryDidChange(folderWatcher: DirectoryWatcher)
}

class DirectoryWatcher: NSObject {
    var path :NSURL
    var source: dispatch_source_t!
    var delegate: DirectoryWatcherDelegate
    init(_ dirPath:NSURL, delegate:DirectoryWatcherDelegate) {
        path = dirPath
        self.delegate = delegate
        super.init()
        self.o()
    }
    
    func o() {
        let observerQueue = dispatch_queue_create("aaa", DISPATCH_QUEUE_CONCURRENT)
        let fileDescr = open(path.fileSystemRepresentation, O_EVTONLY);// observe file system events for particular path - you can pass here Documents directory path
        //observer queue is my private dispatch_queue_t object
        if fileDescr < 0 {
            return
        }
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, UInt(fileDescr), DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_LINK | DISPATCH_VNODE_EXTEND, observerQueue);// create dispatch_source object to observe vnode events
        dispatch_source_set_registration_handler(source, {
            print("registered for observation");
            //event handler is called each time file system event of selected type (DISPATCH_VNODE_*) has occurred
            dispatch_source_set_event_handler(self.source, {

                let flags = dispatch_source_get_data(self.source);//obtain flags
                print("%lu",flags);
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
            
            dispatch_source_set_cancel_handler(self.source, {
                close(fileDescr);
                });
            });
//
//        //we have to resume dispatch_objects
        dispatch_resume(source);
//
//        return source;
    }
}
