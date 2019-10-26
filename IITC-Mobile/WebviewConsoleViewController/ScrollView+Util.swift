//
//  ScrollView+Util.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/24.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

extension UIScrollView {
//    func isTopVisible() -> Bool {
//        return true
//    }

    func isBottomVisible() -> Bool {
        if #available(iOS 11.0, *) {
            return self.contentOffset.y + self.bounds.size.height - self.adjustedContentInset.bottom >= self.contentSize.height
        } else {
            return self.contentOffset.y + self.bounds.size.height - self.contentInset.bottom >= self.contentSize.height
        }
    }
}
