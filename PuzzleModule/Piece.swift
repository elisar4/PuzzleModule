//  Piece.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

enum PieceRotation: Int
{
    case origin = 0, right = 1, left = 2, upside = 3 
    
    var nextSide: PieceRotation {
        switch self {
        case .origin:   return .right
        case .right:    return .upside
        case .upside:   return .left
        case .left:     return .origin
        }
    }
    
    var angle: CGFloat {
        switch self {
        case .origin:   return 0.0
        case .right:    return -CGFloat.pi * 0.5
        case .upside:   return CGFloat.pi
        case .left:     return CGFloat.pi * 0.5
        }
    }
}

class Piece: UIView, PieceItemOutput
{
    
    public func unsub()
    {
        self.gestureRecognizers?.forEach({ (gr) in
            self.removeGestureRecognizer(gr)
        })
        self.item.output = nil
        self.removeFromSuperview()
    }
    
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
                self.output?.didRotate(piece: self)
                self.isRotating = false
            }
        } else {
            self.rotation = to
            self.output?.didRotate(piece: self)
            self.isRotating = false
        }
    }
    
    func animateRotationFromPiece(_ piece: Piece, to: PieceRotation, lx: Int, ly: Int) {
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
                if self == piece {
                    self.item.gridX = lx
                    self.item.gridY = ly
                } else {
                    let ldx = self.item.col - piece.item.col
                    let ldy = self.item.row - piece.item.row
                    if to == .right {
                        self.item.gridX = lx + ldy
                        self.item.gridY = ly - ldx
                    } else if to == .upside {
                        self.item.gridX = lx - ldx
                        self.item.gridY = ly - ldy
                    } else if to == .left {
                        self.item.gridX = lx - ldy
                        self.item.gridY = ly + ldx
                    } else if to == .origin {
                        self.item.gridX = lx + ldx
                        self.item.gridY = ly + ldy
                    }
                }
            }
            self.isRotating = false
            
            if piece == self {
                self.output?.didRotate(piece: self)
            }
        }
    }
    
    func canGroup(withPiece piece: Piece) -> Bool
    {
        if piece.item.uid == self.item.uid {
            return false
        }
        
        if piece.rotation != self.rotation {
            return false
        }
        
        if piece.group?.containsPiece(self) ?? false {
            return false
        }
        
        return self.item.canGroup(withItem: piece.item, atRotation: self.rotation)
    }
    
    init(withItem item: PieceItem, originImage: UIImage)
    {
        self.item = item
        
        super.init(frame: item.oframeScaled)
        
        let cgi = originImage.cgImage!
        let im = cgi.cropping(to: item.oframeScaled)
        
        var trans = CGAffineTransform(translationX: -item.oframe.origin.x,
                                      y: -item.oframe.origin.y)
        let mask = CAShapeLayer()
        mask.path = item.path.copy(using: &trans)
        mask.fillColor = UIColor.blue.cgColor
        mask.transform = CATransform3DMakeScale(item.scale, item.scale, item.scale)
        self.img.layer.mask = mask
        self.img.layer.anchorPoint = CGPoint(x: 0, y: 0)
        self.img.frame = self.bounds
        self.img.image = UIImage(cgImage: im!)
        self.addSubview(self.img)
        
        self.rotation = item.rotation
        
        item.output = self
        
        item.snapToOriginGridCell()
        
        self.updateLastAction()
        
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.shouldRasterize = true
        
        self.isUserInteractionEnabled = true
        if !item.fixed
        {
            let tap = UITapGestureRecognizer(target: self, action: #selector(Piece.tap(_:)))
            self.addGestureRecognizer(tap)
        }
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        if self.group?.isLocked ?? false {
            return
        }
        if self.isRotating || self.isMoving {
            return
        }
        self.isRotating = true
        self.updateLastAction()
        
        if let gr = self.group {
            gr.didRotatePiece(piece: self, to: self.rotation.nextSide)
        } else {
            self.rotate(to: self.rotation.nextSide)
        }
    }
    
    func updateLastAction()
    {
        self.lastAction = Piece.getNextLastAction()
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer)
    {
        if self.group?.isLocked ?? false
        {
            if sender.state == .began
            {
                UIView.animate(withDuration: 0.2,
                               animations: {
                    self.group?.showLockedEffect()
                })
            } else if sender.state == .ended
            {
                UIView.animate(withDuration: 0.2,
                               animations: {
                    self.group?.hideLockedEffect()
                })
            }
            return
        }
        if self.isRotating
        {
            return
        }
        if sender.state == .began
        {
            self.updateLastAction()
            self.layer.zPosition = 1500000.0
            self.group?.pieces.forEach({ (p) in
                p.layer.zPosition = 1500000.0
            })
            if self.group == nil
            {
                self.output?.didPickSinglePiece(self)
            }
        } else if sender.state == .changed
        {
            //move
            let translation = sender.translation(in: self.superview)
            
            self.move(by: translation)
            
            self.group?.didMovePiece(piece: self, by: translation)
            
            sender.setTranslation(CGPoint.zero, in: self)
            
            if self.group == nil
            {
                self.output?.didMoveSinglePiece(self)
            }
        } else if sender.state == .ended
            || sender.state == .cancelled
            || sender.state == .failed
        {
            if self.group == nil {
                if self.output?.didDropSinglePiece(self) ?? false {
                    return
                }
            }
            
            let LGX = item.gridX
            let LGY = item.gridY
            let gr = group
            
            let translation = self.output?.correctedSnapPoint(forPiece: self) ?? self.item.deltaXY(x: self.item.nearestGX, y: self.item.nearestGY)
            UIView.animate(withDuration: 0.15, animations: {
                self.move(by: translation)
                gr?.didMovePiece(piece: self, by: translation)
            }, completion: { (finished) in
                if finished {
                    self.isMoving = false
                    self.item.snapToNearestGridCell()
                    let dx = self.item.gridX - LGX
                    let dy = self.item.gridY - LGY
                    gr?.snapToGrid(piece: self.item.uid, dx: dx, dy: dy)
                    self.dispatchSnap()
                }
            })
        }
    }
    
    func showLockedEffect() {
        self.alpha = 0.45
    }
    
    func hideLockedEffect() {
        self.alpha = 1.0
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
    
    func snapToGrid(_ dispatch: Bool = true, group: Bool = false) {
        self.isMoving = false
        if !group {
            self.item.snapToNearestGridCell()
        }
        if dispatch {
            self.dispatchSnap()
        }
    }
    
    func snapToGrid(_ dispatch: Bool = true, dx: Int, dy: Int) {
        isMoving = false
        item.gridX += dx
        item.gridY += dy
        if dispatch {
            dispatchSnap()
        }
    }
    
    func dispatchSnap()
    {
        self.output?.didSnap(piece: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var render: UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        if self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        {
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img
        }
        return nil
    }
}

extension Piece: UIGestureRecognizerDelegate
{
    
}
