//  UIView+AnchorPoint.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension UIView
{
    var mAnchor: CGPoint {
        get {
            return self.layer.anchorPoint
        }
        set {
            CATransaction.instant {
                let oldFrame = self.frame
                self.layer.anchorPoint = newValue
                self.frame = oldFrame
            }
        }
    }
}
