//
//  CopyPortalLinkActivity.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2018/1/14.
//  Copyright © 2018年 IITC. All rights reserved.
//

import UIKit

class CopyPortalLinkActivity: UIActivity {
    var url: URL?

    override class var activityCategory: UIActivity.Category {
        return .action
    }

    override var activityType: UIActivity.ActivityType {
        return .copyToPasteboard
    }

    override var activityTitle: String? {
        return "Copy Portal Link"
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "ic_link")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        if activityItems.count == 3 {
            if let url = activityItems[1] as? URL {
                return url.host == "www.ingress.com" || url.host == "intel.ingress.com"
            }
        }
        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        if let url = activityItems[1] as? URL {
            self.url = url
        }
    }

    override func perform() {
        if self.url != nil {
            UIPasteboard.general.url = self.url
        }
        self.activityDidFinish(true)
    }

}
