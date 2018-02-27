//  UIView+AnchorPoint.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension UIView
{
    
    var mAnchorXY: CGPoint {
        get {
            return self.layer.anchorPoint
        }
        set {
            let ax = newValue.x / self.bounds.width
            let ay = newValue.y / self.bounds.height
            self.mAnchor = CGPoint(x: ax, y: ay)
        }
    }
    
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
