//  PieceItem.swift
//  Created by Vladimir Roganov on 01.05.17.

import Foundation
import CoreGraphics

protocol PieceItemOutput: class {
    var frame: CGRect {get set}
}

class PieceItem {
    weak var output: PieceItemOutput?
    
    var rotation: PieceRotation = .origin
    
    var locked: Bool = false
    
    var inPalette: Bool = true
    
    var rotationTransform: CGAffineTransform {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: ax, y: ay)
        t = t.rotated(by: rotation.angle)
        t = t.translatedBy(x: -ax, y: -ay)
        return t
    }
    
    var gridX: Int = 0 {
        didSet {
            if let out = output {
                out.frame = out.frame.rect(withX: scaledSize * CGFloat(dx) + ox*scale)
            }
        }
    }
    
    var gridY: Int = 0 {
        didSet {
            if let out = output {
                out.frame = out.frame.rect(withY: scaledSize * CGFloat(dy) + oy*scale)
            }
        }
    }
    
    var dx: Int {
        return gridX - col
    }
    
    var dy: Int {
        return gridY - row
    }
    
    var nearestGX: Int {
        if let out = output {
            let gxf = (out.frame.origin.x + ax - scaledSize * 0.5) / scaledSize
            return (gxf < 0) ? Int(gxf - 0.5) : Int(gxf + 0.5)
        }
        return 0
    }
    
    var nearestGY: Int {
        if let out = output {
            let gfy = (out.frame.origin.y + ay - scaledSize * 0.5) / scaledSize
            return (gfy < 0) ? Int(gfy - 0.5) : Int(gfy + 0.5)
        }
        return 0
    }
    
    var translationToNearestSnapPoint: CGPoint {
        return translationToGridCell(col: nearestGX, row: nearestGY)
    }
    
    func translationToGridCell(col: Int, row: Int) -> CGPoint {
        if let out = output {
            let nX = scaledSize * CGFloat(col - self.col) + ox*scale
            let nY = scaledSize * CGFloat(row - self.row) + oy*scale
            return CGPoint(x: nX - out.frame.origin.x, y: nY - out.frame.origin.y)
        }
        return CGPoint.zero
    }
    
    func snapToNearestGridCell() {
        gridX = nearestGX
        gridY = nearestGY
    }
    
    func snapToOriginGridCell() {
        gridX = col
        gridY = row
    }
    
    func canGroup(withItem item: PieceItem, atRotation rotation: PieceRotation) -> Bool {
        let odx = col - item.col
        let ody = row - item.row
        
        if odx > 1 || odx < -1 || ody > 1 || ody < -1 {
            return false
        }
        
        if (ody == 1 && odx == 1)
            || (ody == -1 && odx == -1) {
            return false
        }
        
        if (ody == -1 && odx == 1)
            || (ody == 1 && odx == -1) {
            return false
        }
        
        let cgx = gridX - item.gridX
        let cgy = gridY - item.gridY
        if rotation == .origin {
            if cgx == odx && cgy == ody {
                return true
            }
        } else if rotation == .upside {
            if cgx == odx * -1 && cgy == ody * -1 {
                return true
            }
        } else if rotation == .left {
            if cgx == ody * -1 && cgy == odx {
                return true
            }
        } else if rotation == .right {
            if cgx == ody && cgy == odx * -1 {
                return true
            }
        }
        
        return false
    }
    
    var anchor: CGPoint {
        return CGPoint(x: ax/(ow*scale), y: ay/(oh*scale))
    }
    
    var uidInt: Int {
        return self.uid.hashValue
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
    
    let oframeScaled: CGRect
    
    let ax: CGFloat
    let ay: CGFloat
    let a: CGPoint
    
    let scale: CGFloat
    
    let size: CGFloat
    let scaledSize: CGFloat
    
    let path: CGPath
    
    init(uid: String, row: Int, col: Int, path: CGPath, scale: CGFloat, size: CGFloat, fixed: Bool, originFrame: CGRect) {
        self.uid = uid
        self.row = row
        self.col = col
        self.fixed = fixed
        self.path = path
        self.oframe = originFrame
        self.oframeScaled = CGRect(x: originFrame.origin.x*scale,
                                   y: originFrame.origin.y*scale,
                                   width: originFrame.width*scale,
                                   height: originFrame.height*scale)
        self.ox = oframe.origin.x
        self.oy = oframe.origin.y
        self.ow = oframe.size.width
        self.oh = oframe.size.height
        self.scale = scale
        self.size = size
        self.scaledSize = size * scale
        
        self.ax = (size * 0.5 + size * CGFloat(col) - ox)*scale
        self.ay = (size * 0.5 + size * CGFloat(row) - oy)*scale
        self.a = CGPoint(x: ax, y: ay)
        
        if !fixed {
            if let r = PieceRotation(rawValue: Int(arc4random() % 4)) {
                self.rotation = r
            }
        }
    }
}
