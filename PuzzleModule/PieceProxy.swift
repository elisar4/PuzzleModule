//  PieceProxy.swift
//  Created by Vladimir Roganov on 07.05.17.

import UIKit

class PieceProxy: UIView {
    
    static var nextLastAction: CGFloat = 50000.0
    static func getNextLastAction() -> CGFloat
    {
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
    
    func rotate(to: PieceRotation, animated: Bool = true)
    {
        if animated
        {
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
    
    func animateRotationFromPiece(_ piece: Piece, to: PieceRotation)
    {
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
    
    init(withItem item: PieceItem, originImage: UIImage)
    {
        self.item = item
        
        super.init(frame: CGRect(x: 0, y: 0, width: item.osize.width-item.corrX-item.ox, height: item.osize.height-item.corrY-item.oy))
        
        //backgroundColor = .green
        
        let cgi = originImage.cgImage!
        let im = cgi.cropping(to: CGRect(x: item.ox+item.corrX, y: item.oy+item.corrY, width: item.osize.width-item.corrX-item.ox, height: item.osize.height-item.corrY-item.oy))
        
        var trans = CGAffineTransform(translationX: -item.path.boundingBoxOfPath.origin.x-item.corrX*1.5,
                                      y: -item.path.boundingBoxOfPath.origin.y-item.corrY*1.5)
        let mask = CAShapeLayer()
        mask.anchorPoint = .zero
        mask.path = item.path.copy(using: &trans)
        mask.fillColor = UIColor.blue.cgColor
        mask.transform = CATransform3DMakeScale(item.scale, item.scale, item.scale)
        self.img.layer.mask = mask
        self.img.layer.anchorPoint = CGPoint(x: 0, y: 0)
        self.img.frame = self.bounds
        self.img.image = UIImage(cgImage: im!)
        self.addSubview(self.img)
        
        self.rotation = item.rotation
        
        item.snapToOriginGridCell()
        
        self.updateLastAction()
        
        //self.layer.rasterizationScale = UIScreen.main.scale
        //self.layer.shouldRasterize = true
    }
    
    func updateLastAction()
    {
        self.lastAction = Piece.getNextLastAction()
    }
    
    func setPosition(col: Int, row: Int, rotation: Int)
    {
        self.item.gridX = col
        self.item.gridY = row
        if let rot = PieceRotation(rawValue:rotation)
        {
            self.rotation = rot
        }
    }
    
    func randomPosition(maxCol: Int, maxRow: Int)
    {
        self.item.gridX = Int(arc4random()%UInt32(maxCol))
        self.item.gridY = Int(arc4random()%UInt32(maxRow))
    }
    
    func move(by: CGPoint)
    {
        self.isMoving = true
        self.frame = self.frame.offsetBy(dx: by.x, dy: by.y)
    }
    
    func snapToGrid(_ dispatch: Bool = true)
    {
        self.isMoving = false
        self.item.snapToNearestGridCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var render: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        if self.drawHierarchy(in: bounds, afterScreenUpdates: true) {
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img
        }
        return nil
    }
}

extension UIImage {
    func cropImageByAlpha() -> UIImage {
        let cgImage = self.cgImage!
        let context = createARGBBitmapContextFromImage(inImage: cgImage)
        let height = cgImage.height
        let width = cgImage.width
        
        
        var rect: CGRect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        context?.draw(cgImage, in: rect)
        
        let dd = context!.data?.assumingMemoryBound(to: CUnsignedChar.self)
        
        let data = UnsafePointer<CUnsignedChar>(dd.unsafelyUnwrapped)
        
        var minX = width
        var minY = height
        var maxX: Int = 0
        var maxY: Int = 0
        
        //Filter through data and look for non-transparent pixels.
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (width * y + x) * 4 /* 4 for A, R, G, B */
                
                if data[Int(pixelIndex)] != 0 { //Alpha value is not zero pixel is not transparent.
                    if (x < minX) {
                        minX = x
                    }
                    if (x > maxX) {
                        maxX = x
                    }
                    if (y < minY) {
                        minY = y
                    }
                    if (y > maxY) {
                        maxY = y
                    }
                }
            }
        }
        
        rect = CGRect(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX-minX), height: CGFloat(maxY-minY))
        let imageScale:CGFloat = self.scale
        let cgiImage = self.cgImage!.cropping(to: rect)
        return UIImage(cgImage: cgiImage!, scale: imageScale, orientation: self.imageOrientation)
    }
    
    private func createARGBBitmapContextFromImage(inImage: CGImage) -> CGContext? {
        
        let width = inImage.width
        let height = inImage.height
        
        let bitmapBytesPerRow = width * 4
        let bitmapByteCount = bitmapBytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapData = malloc(bitmapByteCount)
        if bitmapData == nil {
            return nil
        }
        
        let context = CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        return context
    }
}
