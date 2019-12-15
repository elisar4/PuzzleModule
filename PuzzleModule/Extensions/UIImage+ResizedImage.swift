//  UIImage+ResizedImage.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension UIImage {
    
    func resizedImage(scale: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContext(rect.size)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = newImage {
            return image
        }
        return self
    }
    
    /// Scale type: ScaleAspectFill
    func resizedImage(toSize: CGSize) -> UIImage {
        let ow = size.width
        let oh = size.height
        
        let factor = max(toSize.width / ow, toSize.height / oh)
        
        let nw = ow * factor
        let nh = oh * factor
        let nx = (toSize.width - nw) * 0.5
        let ny = (toSize.height - nh) * 0.5
        
        UIGraphicsBeginImageContext(CGSize(width: nw, height: nh))
        draw(in: CGRect(x: nx, y: ny, width: nw, height: nh))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = newImage {
            return image
        }
        return self
    }
}
