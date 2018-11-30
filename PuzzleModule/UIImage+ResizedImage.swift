//  UIImage+ResizedImage.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

extension UIImage {
    func resizedImage(scale: CGFloat) -> UIImage {
        let ow = self.size.width*scale
        let oh = self.size.height*scale
        
        UIGraphicsBeginImageContext(CGSize(width: ow, height: oh))
        self.draw(in: CGRect(x: 0, y: 0, width: ow, height: oh))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let ni = newImage {
            return ni
        }
        return self
    }
    
    //scale type: ScaleAspectFill
    func resizedImage(toSize: CGSize) -> UIImage
    {
        let ow = self.size.width
        let oh = self.size.height
        
        let factor = max(toSize.width / ow, toSize.height / oh)
        
        let nw = ow * factor
        let nh = oh * factor
        let nx = (toSize.width - nw) * 0.5
        let ny = (toSize.height - nh) * 0.5
        
        UIGraphicsBeginImageContext(CGSize(width: nw, height: nh))
        self.draw(in: CGRect(x: nx, y: ny, width: nw, height: nh))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let ni = newImage {
            return ni
        }
        return self
    }
}
