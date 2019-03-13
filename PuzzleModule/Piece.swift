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

class Piece: UIView, PieceItemOutput {
    
    public func unsub() {
        gestureRecognizers?.forEach({ (gr) in
            self.removeGestureRecognizer(gr)
        })
        item.output = nil
        removeFromSuperview()
    }
    
    static var nextLastAction: CGFloat = 50000.0
    static func getNextLastAction() -> CGFloat {
        Piece.nextLastAction += 0.1
        return Piece.nextLastAction
    }
    
    let item: PieceItem
    
    let img: UIImageView = UIImageView()
//    let proxyImage: UIImageView = UIImageView()
    
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
    
    func blinkPoint(_ piece: Piece) -> CGPoint {
        let pcx: CGFloat
        
        let ss = item.size * item.scale
        
        let dx = piece.item.col - item.col
        if dx == 0 {
            pcx = item.ax
        } else if dx == 1 {
            pcx = item.ax + ss
        } else {
            pcx = item.ax - ss
        }
        
        let pcy: CGFloat
        
        let dy = piece.item.row - item.row
        if dy == 0 {
            pcy = item.ay
        } else if dy == 1 {
            pcy = item.ay + ss
        } else {
            pcy = item.ay - ss
        }
        
        return CGPoint(x: pcx, y: pcy)
    }
    
    func rotate(to: PieceRotation, animated: Bool = true) {
        if animated {
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
    
    func canGroup(withPiece piece: Piece) -> Bool {
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
    
    init(withItem item: PieceItem, originImage: UIImage) {
        self.item = item
        
        super.init(frame: item.oframeScaled)
        
        let cgi = originImage.cgImage!
        let im = cgi.cropping(to: item.oframeScaled)
        
        var trans = CGAffineTransform(translationX: item.oframe.origin.x, y: item.oframe.origin.y).scaledBy(x: item.scale, y: item.scale).translatedBy(x: -item.oframe.origin.x, y: -item.oframe.origin.y)
        let p = item.path.copy(using: &trans)!
        var t = CGAffineTransform(translationX: -item.oframe.origin.x, y: -item.oframe.origin.y)
        img.layer.anchorPoint = CGPoint(x: 0, y: 0)
        img.frame = bounds
        img.contentMode = .topLeft
        img.image = UIImage(cgImage: im!).croppedWith(path: p.copy(using: &t)!)
        addSubview(img)
        
        rotation = item.rotation
        
        item.output = self
        
        item.snapToOriginGridCell()
        
        updateLastAction()
        
        isUserInteractionEnabled = true
        if !item.fixed {
            let tap = UITapGestureRecognizer(target: self, action: #selector(Piece.tap(_:)))
            addGestureRecognizer(tap)
        }
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        if group?.isLocked ?? false {
            return
        }
        if isRotating || isMoving {
            return
        }
        isRotating = true
        updateLastAction()
        
        if let gr = group {
            gr.didRotatePiece(piece: self, to: rotation.nextSide)
        } else {
            rotate(to: rotation.nextSide)
        }
    }
    
    func updateLastAction() {
        lastAction = Piece.getNextLastAction()
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        if group?.isLocked ?? false {
            if sender.state == .began {
                UIView.animate(withDuration: 0.2,
                               animations: {
                    self.group?.showLockedEffect()
                })
            } else if sender.state == .ended {
                UIView.animate(withDuration: 0.2,
                               animations: {
                    self.group?.hideLockedEffect()
                })
            }
            return
        }
        if isRotating {
            return
        }
        if sender.state == .began {
            output?.pickSingleEvent()
            self.updateLastAction()
            self.layer.zPosition = 1500000.0
            self.group?.pieces.forEach({ (p) in
                p.layer.zPosition = 1500000.0
            })
            if self.group == nil {
                self.output?.didPickSinglePiece(self)
            }
        } else if sender.state == .changed {
            //move
            let translation = sender.translation(in: self.superview)
            
            self.move(by: translation)
            
            self.group?.didMovePiece(piece: self, by: translation)
            
            sender.setTranslation(CGPoint.zero, in: self)
            
            if self.group == nil {
                self.output?.didMoveSinglePiece(self)
            }
        } else if sender.state == .ended
            || sender.state == .cancelled
            || sender.state == .failed {
            output?.dropSingleEvent()
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
        alpha = 0.45
    }
    
    func hideLockedEffect() {
        alpha = 1.0
    }
    
    func setPosition(col: Int, row: Int, rotation: Int) {
        item.gridX = col
        item.gridY = row
        if let rot = PieceRotation(rawValue: rotation) {
            self.rotation = rot
        }
    }
    
    func randomPosition(maxCol: Int, maxRow: Int) {
        item.gridX = Int(arc4random()%UInt32(maxCol))
        item.gridY = Int(arc4random()%UInt32(maxRow))
    }
    
    func move(by: CGPoint) {
        isMoving = true
        frame = frame.offsetBy(dx: by.x, dy: by.y)
    }
    
    func snapToGrid(_ dispatch: Bool = true, group: Bool = false) {
        isMoving = false
        if !group {
            item.snapToNearestGridCell()
        }
        if dispatch {
            dispatchSnap()
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
    
    func dispatchSnap() {
        output?.didSnap(piece: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Piece: UIGestureRecognizerDelegate {
    
}
