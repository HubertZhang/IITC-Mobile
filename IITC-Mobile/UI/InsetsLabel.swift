//
//  InsetsLabel.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2018/5/4.
//  Copyright © 2018年 IITC. All rights reserved.
//

import UIKit

@IBDesignable
class InsetsLabel: UILabel {
    @IBInspectable public var bottomInset: CGFloat {
        get { return textInsets.bottom }
        set { textInsets.bottom = newValue }
    }
    @IBInspectable public var leftInset: CGFloat {
        get { return textInsets.left }
        set { textInsets.left = newValue }
    }
    @IBInspectable public var rightInset: CGFloat {
        get { return textInsets.right }
        set { textInsets.right = newValue }
    }
    @IBInspectable public var topInset: CGFloat {
        get { return textInsets.top }
        set { textInsets.top = newValue }
    }

    public var textInsets: UIEdgeInsets = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(textInsets, forKey: "textInsets")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textInsets = aDecoder.decodeUIEdgeInsets(forKey: "textInsets")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        preferredMaxLayoutWidth = frame.width - (leftInset + rightInset)
    }

    override open var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        let width = size.width + leftInset + rightInset
        let height = size.height + topInset + bottomInset
        return CGSize(width: width, height: height)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, textInsets))
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
