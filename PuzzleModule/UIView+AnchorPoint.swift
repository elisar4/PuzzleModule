//  UIView+AnchorPoint.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension UIView {
    
    var mAnchorXY: CGPoint {
        get {
            return layer.anchorPoint
        }
        set {
            mAnchor = CGPoint(x: newValue.x / bounds.width,
                              y: newValue.y / bounds.height)
        }
    }
    
    var mAnchor: CGPoint {
        get {
            return layer.anchorPoint
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
