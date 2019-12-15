//  UIView+EAGeom.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension CGPoint {
    
    func distance(toPoint p: CGPoint) -> CGFloat {
        return sqrt(pow((p.x - x), 2) + pow((p.y - y), 2))
    }
}

extension CGRect {
    
    func rect(withX x: CGFloat) -> CGRect {
        return CGRect(x: x, y: origin.y, width: size.width, height: size.height)
    }
    
    func rect(withY y: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: y, width: size.width, height: size.height)
    }
    
    func scaled(by: CGFloat) -> CGRect {
        return CGRect(x: origin.x * by, y: origin.y * by, width: size.width * by, height: size.height * by)
    }
}
