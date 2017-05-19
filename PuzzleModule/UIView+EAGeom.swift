//  UIView+EAGeom.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension UIView
{
    
}

extension CGPoint
{
    func distance(toPoint p:CGPoint) -> CGFloat
    {
        return sqrt(pow((p.x - x), 2) + pow((p.y - y), 2))
    }
}

extension CGRect
{
    func rect(withX x: CGFloat) -> CGRect
    {
        return CGRect(x: x, y: self.origin.y, width: self.size.width, height: self.size.height)
    }
    
    func rect(withY y: CGFloat) -> CGRect
    {
        return CGRect(x: self.origin.x, y: y, width: self.size.width, height: self.size.height)
    }
    
    func scaled(by: CGFloat) -> CGRect
    {
        return CGRect(x: self.origin.x * by, y: self.origin.y * by, width: self.size.width * by, height: self.size.height * by)
    }
}
