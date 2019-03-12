//  PieceProxy.swift
//  Created by Vladimir Roganov on 07.05.17.

import UIKit

class PieceProxy: UIView {
    
    static var nextLastAction: CGFloat = 50000.0
    static func getNextLastAction() -> CGFloat {
        Piece.nextLastAction += 0.1
        return Piece.nextLastAction
    }
    
    let item: PieceItem
    
    let img: UIImageView = UIImageView()
    
    var group: PieceGroup?
    var output: PieceOutput?
    
    var isRotating = false
    var isMoving = false
    var lastAction: CGFloat = 0.0
    
    var rotation: PieceRotation = .origin {
        didSet {
            self.item.rotation = self.rotation
            self.img.transform = self.item.rotationTransform
        }
    }
    
    func rotate(to: PieceRotation, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.15, animations: {
                self.rotation = to
            }) { (finish) in
                self.isRotating = false
            }
        } else {
            self.rotation = to
            self.isRotating = false
        }
    }
    
    func animateRotationFromPiece(_ piece: Piece, to: PieceRotation) {
        let oldT = self.layer.transform
        let oldAnchor = self.mAnchor
        
        let ap = self.convert(piece.item.a, from: piece)
        self.mAnchor = CGPoint(x: ap.x / (self.frame.width), y: ap.y / (self.frame.height))
        
        UIView.animate(withDuration: 0.25, animations: {
            self.layer.transform = CATransform3DRotate(CATransform3DIdentity, PieceRotation.right.angle, 0.0, 0.0, 1.0)
        }) { (finished) in
            self.mAnchor = oldAnchor
            
            CATransaction.instant {
                self.layer.transform = oldT
                self.rotation = to
                self.item.snapToNearestGridCell()
            }
            self.isRotating = false
        }
    }
    
    init(withItem item: PieceItem, originImage: UIImage) {
        self.item = item
        super.init(frame: item.oframeScaled)
        let cgi = originImage.cgImage!
        let im = cgi.cropping(to: item.oframeScaled)
        var trans = CGAffineTransform(translationX: item.oframe.origin.x, y: item.oframe.origin.y).scaledBy(x: item.scale, y: item.scale).translatedBy(x: -item.oframe.origin.x, y: -item.oframe.origin.y)
        let p = item.path.copy(using: &trans)!
        var t = CGAffineTransform(translationX: -item.oframe.origin.x, y: -item.oframe.origin.y)
        img.frame = bounds
        img.image = UIImage(cgImage: im!).croppedWith(path: p.copy(using: &t)!)
        rotation = item.rotation
        item.snapToOriginGridCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var render: UIImage? {
        return img.image
    }
}

extension UIImage {
    func croppedWith(path: CGPath) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIBezierPath(cgPath: path).addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
