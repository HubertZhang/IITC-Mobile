//
//  ConsoleInputActionButtonViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/19.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

@IBDesignable class ConsoleInputActionView: UIView {

    @IBOutlet weak var textLabel: UILabel!
//    @IBInspectable var highlightedColor: UIColor = UIColor.blue

    var isDisabled: () -> Bool = {return false}

    var action: () -> Void = {}

    var isHighlighted: Bool = false

    func updateStatus() {
        if self.isDisabled() {
            if #available(iOS 13.0, *) {
                self.textLabel.textColor = UIColor.placeholderText
            } else {
                self.textLabel.textColor = UIColor.darkGray
            }
        } else {
            if #available(iOS 13.0, *) {
                self.backgroundColor = self.isHighlighted ? UIColor(named: "buttonHighlighted") : UIColor.clear
                self.textLabel.textColor = self.isHighlighted ?  UIColor.systemBackground:UIColor.label
            } else {
                self.backgroundColor = self.isHighlighted ? UIColor(red: 0, green: 0.4609375, blue: 1, alpha: 1) : UIColor.clear
                self.textLabel.textColor = self.isHighlighted ?  UIColor.white:UIColor.black
            }
        }

    }

}

class ConsoleInputActionButtonViewController: UIViewController {
    @IBOutlet weak var buttonsView: UIStackView!

    private var buttons: [ConsoleInputActionView] = []

    @IBOutlet weak var backgroundView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            self.view.layer.shadowColor = UIColor.label.cgColor
        } else {
            // Fallback on earlier versions
        }
        self.view.layer.shadowOpacity = 0.3
        self.view.layer.shadowOffset = CGSize(width: 0, height: 2)
        // Do any additional setup after loading the view.
        for view in self.buttons {
            self.buttonsView.addArrangedSubview(view)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let radius: CGFloat = 5
        let path = UIBezierPath()

        let points: [(CGPoint)] = [
            (CGPoint(x: 0, y: 0)),

            (CGPoint(x: self.view.bounds.maxX, y: 0)),
            (CGPoint(x: self.view.bounds.maxX, y: self.view.bounds.maxY)),

            (CGPoint(x: self.view.bounds.maxX - 32, y: self.view.bounds.maxY)),

            (CGPoint(x: self.view.bounds.maxX - 32, y: self.view.bounds.maxY - 25)),
            (CGPoint(x: 0, y: self.view.bounds.maxY - 25))
        ]


        path.move(to: CGPoint(x: 0, y: radius))
        path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: .pi, endAngle: .pi*1.5, clockwise: true)
        path.addLine(to: CGPoint(x: points[1].x-radius, y: points[1].y))
        path.addArc(withCenter: CGPoint(x: points[1].x-radius, y: points[1].y+radius), radius: radius, startAngle: .pi*1.5, endAngle: .pi*2, clockwise: true)
        path.addLine(to: CGPoint(x: points[2].x, y: points[2].y-radius))
        path.addArc(withCenter: CGPoint(x: points[2].x-radius, y: points[2].y - radius), radius: radius, startAngle: 0, endAngle: .pi/2, clockwise: true)
        path.addLine(to: CGPoint(x: points[3].x+radius, y: points[3].y))
        path.addArc(withCenter: CGPoint(x: points[3].x+radius, y: points[3].y-radius), radius: radius, startAngle: .pi*0.5, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: points[4].x, y: points[4].y+radius))
        path.addArc(withCenter: CGPoint(x: points[4].x-radius, y: points[4].y+radius), radius: radius, startAngle: .pi*2, endAngle: .pi*1.5, clockwise: false)
        path.addLine(to: CGPoint(x: points[5].x+radius, y: points[5].y))
        path.addArc(withCenter: CGPoint(x: points[5].x+radius, y: points[5].y-radius), radius: radius, startAngle: .pi*0.5, endAngle: .pi, clockwise: true)
        path.close()

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.backgroundView.layer.mask = mask
        self.view.layer.shadowPath = path.cgPath
    }

    func addAction(withTitle title: String, disabler: @escaping () -> Bool, action: @escaping () -> Void ) {
        let views = UINib(nibName: "ConsoleInputActionView", bundle: nil).instantiate(withOwner: nil, options: nil)
        let view = views[0] as! ConsoleInputActionView
        view.textLabel.text = title
        view.isDisabled = disabler
        view.action = action
        if self.isViewLoaded {
            self.buttonsView.addArrangedSubview(view)
        } else {
            self.buttons.append(view)
        }
    }

    func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: buttonsView)
        for view in buttonsView.arrangedSubviews {
            guard let view = view as? ConsoleInputActionView else {
                continue
            }
            view.isHighlighted = false
            if view.frame.contains(location) {
                if gestureRecognizer.state == .changed {
                    view.isHighlighted = true
                } else if gestureRecognizer.state == .ended {
                    if !view.isDisabled() {
                        view.action()
                    }
                }
            }
            view.updateStatus()
        }
    }

}
