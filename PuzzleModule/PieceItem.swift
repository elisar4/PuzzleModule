//  PieceItem.swift
//  Created by Vladimir Roganov on 01.05.17.

import Foundation
import CoreGraphics

protocol PieceItemOutput: class
{
    var frame: CGRect {get set}
}

class PieceItem
{
    weak var output: PieceItemOutput?
    
    var rotation: PieceRotation = .origin
    
    var locked: Bool = false
    
    var inPalette: Bool = true
    
    var rotationTransform: CGAffineTransform {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: self.ax, y: self.ay)
        t = t.rotated(by: self.rotation.angle)
        t = t.translatedBy(x: -self.ax, y: -self.ay)
        return t
    }
    
    var gridX: Int = 0 {
        didSet {
            if let out = self.output
            {
                out.frame = out.frame.rect(withX: self.size * CGFloat(self.dx) + self.ox)
            }
        }
    }
    
    var gridY: Int = 0 {
        didSet {
            if let out = self.output
            {
                out.frame = out.frame.rect(withY: self.size * CGFloat(self.dy) + self.oy)
            }
        }
    }
    
    var dx: Int {
        return self.gridX - self.col
    }
    
    var dy: Int {
        return self.gridY - self.row
    }
    
    var nearestGX: Int {
        if let out = self.output
        {
            let gxf = (out.frame.origin.x + self.ax - self.size * 0.5) / self.size
            return (gxf < 0) ? Int(gxf - 0.5) : Int(gxf + 0.5)
        }
        return 0
    }
    
    var nearestGY: Int {
        if let out = self.output
        {
            let gfy = (out.frame.origin.y + self.ay - self.size * 0.5) / self.size
            return (gfy < 0) ? Int(gfy - 0.5) : Int(gfy + 0.5)
        }
        return 0
    }
    
    var translationToNearestSnapPoint: CGPoint {
        return self.translationToGridCell(col: self.nearestGX, row: self.nearestGY)
    }
    
    func translationToGridCell(col: Int, row: Int) -> CGPoint
    {
        if let out = self.output
        {
            let nX = self.size * CGFloat(col - self.col) + self.ox
            let nY = self.size * CGFloat(row - self.row) + self.oy
            return CGPoint(x: nX - out.frame.origin.x, y: nY - out.frame.origin.y)
        }
        return CGPoint.zero
    }
    
    func snapToNearestGridCell()
    {
        self.gridX = self.nearestGX
        self.gridY = self.nearestGY
    }
    
    func snapToOriginGridCell()
    {
        self.gridX = self.col
        self.gridY = self.row
    }
    
    
    func canGroup(withItem item: PieceItem, atRotation rotation: PieceRotation) -> Bool
    {
        let odx = self.col - item.col
        let ody = self.row - item.row
        
        if odx > 1 || odx < -1 || ody > 1 || ody < -1
        {
            return false
        }
        
        if (ody == 1 && odx == 1)
            || (ody == -1 && odx == -1)
        {
            return false
        }
        
        if (ody == -1 && odx == 1)
            || (ody == 1 && odx == -1)
        {
            return false
        }
        
        if rotation == .origin
        {
            if self.gridX - item.gridX == odx
            {
                if self.gridY - item.gridY == ody
                {
                    return true
                }
            }
        } else if rotation == .upside
        {
            if self.gridX - item.gridX == odx * -1
            {
                if self.gridY - item.gridY == ody * -1
                {
                    return true
                }
            }
        } else if rotation == .left
        {
            if self.gridX - item.gridX == ody * -1
            {
                if self.gridY - item.gridY == odx
                {
                    return true
                }
            }
        } else if rotation == .right
        {
            if self.gridX - item.gridX == ody
            {
                if self.gridY - item.gridY == odx * -1
                {
                    return true
                }
            }
        }
        
        return false
    }
    /*
    func canGroup(withItem item: PieceItem, atRotation rotation: PieceRotation) -> Bool
    {
        let rdx = self.dx - item.dx
        let rdy = self.dy - item.dy
        
        if rdx > 2 || rdx < -2 {
            return false
        }
        
        if rdy > 2 || rdy < -2 {
            return false
        }
        
        if (rdx == 2 && rdy == 2)
            || (rdx == -2 && rdy == -2) {
            return false
        }
        
        let dc = item.col - self.col
        let dr = item.row - self.row
        
        let type = dc != 0
        let type2 = dr != 0
        
        if type && type2
        {
            return false
        }
        
        if dc > 1 || dc < -1
        {
            return false
        }
        
        if dr > 1 || dr < -1
        {
            return false
        }
        
        if rotation == .origin {
            if rdx == 0 && rdy == 0 {
                return true
            }
        }
        
        if rotation == .right {
            if type {
                if (rdx == 1 && rdy == 1)
                    || (rdx == -1 && rdy == -1) {
                    return true
                }
            } else {
                if (rdx == -1 && rdy == 1)
                    || (rdx == 1 && rdy == -1) {
                    return true
                }
            }
        }
        
        if rotation == .left {
            if type {
                if (rdx == -1 && rdy == 1)
                    || (rdx == 1 && rdy == -1) {
                    return true
                }
            } else {
                if (rdx == 1 && rdy == 1)
                    || (rdx == -1 && rdy == -1) {
                    return true
                }
            }
        }
        
        if rotation == .upside {
            if type {
                if (rdx == 2 && rdy == 0)
                    || (rdx == -2 && rdy == 0) {
                    return true
                }
            } else {
                if (rdx == 0 && rdy == 2)
                    || (rdx == 0 && rdy == -2) {
                    return true
                }
            }
        }
        
        return false
    }
    */
    var anchor: CGPoint {
        return CGPoint(x: self.ax/self.ow, y: self.ay/self.oh)
    }
    
    var uidInt: Int {
        return self.uid.hashValue//self.col + self.row * 100000
    }
    
    //MARK: - Init
    
    let uid: String
    let fixed: Bool
    
    let row: Int
    let col: Int
    
    let ox: CGFloat
    let oy: CGFloat
    let ow: CGFloat
    let oh: CGFloat
    let oframe: CGRect
    let osize: CGSize
    let corrX: CGFloat
    let corrY: CGFloat
    
    var rosize: CGSize {
        if rotation == .left || rotation == .right {
            return CGSize(width: osize.height, height: osize.width)
        }
        return osize
    }
    
    var rosizeCorrected: CGSize {
        let w: CGFloat = osize.width - corrX - ox
        let h: CGFloat = osize.height - corrY - oy
        if rotation == .left || rotation == .right {
            return CGSize(width: h, height: w)
        }
        return CGSize(width: w, height: h)
    }
    
    let ax: CGFloat
    let ay: CGFloat
    let a: CGPoint
    
    let scale: CGFloat
    
    let size: CGFloat
    
    let path: CGPath
    
    init(uid: String, row: Int, col: Int, path: CGPath, scale: CGFloat, size: CGFloat, fixed: Bool) {
        self.uid = uid
        self.row = row
        self.col = col
        self.fixed = fixed
        self.path = path
        self.corrX = size*CGFloat(col)
        self.corrY = size*CGFloat(row)
        let ss = path.boundingBoxOfPath.scaled(by: scale)
        self.oframe = ss
        self.ox = oframe.origin.x
        self.oy = oframe.origin.y
        self.ow = oframe.size.width//-oframe.origin.x-corrX
        self.oh = oframe.size.height//-oframe.origin.y-corrY
        self.scale = scale
        self.size = size
        
        self.ax = size * 0.5 + corrX - self.ox
        self.ay = size * 0.5 + corrY - self.oy
        self.a = CGPoint(x: self.ax, y: self.ay)
        
        self.osize = CGSize(width: ow, height: oh)
        
        print("#1233", ss)
        
        if !fixed
        {
            if let r = PieceRotation(rawValue: Int(arc4random() % 4))
            {
                self.rotation = r
            }
        }
    }
}
