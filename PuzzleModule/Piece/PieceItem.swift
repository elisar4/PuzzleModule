//  PieceItem.swift
//  Created by Vladimir Roganov on 01.05.17.

import Foundation
import CoreGraphics

protocol PieceItemOutput2: class {
    //var frame: CGRect {get set}
//    var pSize: CGSize {get set}
//    var pPosition: CGPoint {get set}
}

protocol PieceItemOut: class {
    var point: CGPoint {get set}
    var psize: CGSize {get set}
}

class PieceItem {
    weak var output: PieceItemOut?
    
    var rotation: PieceRotation = .origin
    
    var locked: Bool = false
    
    var inPalette: Bool = true
    
    var isUncompleted: Bool {
        return dx != 0 || dy != 0 || rotation != .origin || !locked
    }
    
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
                out.point = CGPoint(x: size * CGFloat(dx) + ox * scale + ax, y: out.point.y)
            }
        }
    }
    
    var gridY: Int = 0 {
        didSet {
            if let out = output {
                out.point = CGPoint(x: out.point.x, y: size * CGFloat(dy) + oy * scale + ay)
            }
        }
    }
    
    func targetFrame(x: Int, y: Int) -> CGRect {
        if let out = output {
            let fx = CGFloat(x - col) * size + ox * scale
            let fy = CGFloat(y - row) * size + oy * scale
            return CGRect(x: fx, y: fy, width: out.psize.width, height: out.psize.height)
        }
        return .zero
    }
    
    func deltaXY(x: Int, y: Int) -> CGPoint {
        if let out = output {
            let fx = CGFloat(x - col) * size + ox * scale
            let fy = CGFloat(y - row) * size + oy * scale
            return CGPoint(x: fx - out.point.x, y: fy - out.point.y)
        }
        return .zero
    }
    
    var dx: Int {
        return gridX - col
    }
    
    var dy: Int {
        return gridY - row
    }
    
//    let r = sv.convert(piece.frame, to: pieceContainer)
//    
//    let gxf = (r.origin.x + piece.item.ax) / originSize
//    let ngx = (gxf < 0) ? Int(gxf - 0.5) : Int(gxf + 0.5)
//    let gyf = (r.origin.y + piece.item.ay) / originSize
//    let ngy = (gyf < 0) ? Int(gyf - 0.5) : Int(gyf + 0.5)
    var nearestGX: Int {
        if let out = output {
            return Int(out.point.x / size)
        }
        return 0
    }
    
    var nearestGY: Int {
        if let out = output {
            return Int(out.point.y / size)
        }
        return 0
    }
    
    var translationToNearestSnapPoint: CGPoint {
        return translationToGridCell(col: nearestGX, row: nearestGY)
    }
    
    func translationToGridCell(col: Int, row: Int) -> CGPoint {
        if let out = output {
            let nX = size * CGFloat(col - self.col) + ax
            let nY = size * CGFloat(row - self.row) + ay
            return CGPoint(x: nX - out.point.x, y: nY - out.point.y)
        }
        return CGPoint.zero
    }
    
    func nearestGridPoint() -> CGPoint {
//        if let out = output {
//            var fr = out.frame.rect(withX: size * CGFloat(dx) + ox * scale)
//            fr = fr.rect(withY: size * CGFloat(dy) + oy * scale)
//            return fr.origin
            return CGPoint(x: size * CGFloat(dx) + ox * scale, y: size * CGFloat(dy) + oy * scale)
//        }
//        return .zero
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
        return CGPoint(x: ax / (ow * scale), y: ay / (oh * scale))
    }
    
    var uidInt: Int {
        // TODO: fix this to exclude hash overlapping (could cause bugs)
        return uid.hashValue
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
    let ofDelta: CGPoint
    
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
        let _ox = originFrame.origin.x * scale
        let _oy = originFrame.origin.y * scale
        let ofs = CGRect(x: _ox,
                         y: _oy,
                         width: originFrame.width * scale,
                         height: originFrame.height * scale)
        self.ofDelta = CGPoint(x: ofs.minX-CGFloat(Int(_ox)),
                               y: ofs.minY-CGFloat(Int(_oy)))
        let _ow = Int((originFrame.width * scale + 0.5).rounded())// + Int(ofDelta.x.rounded(.up))
        let _oh = Int((originFrame.height * scale + 0.5).rounded())// + Int(ofDelta.y.rounded(.up))
        self.oframeScaled = CGRect(x: Int(originFrame.origin.x * scale),
                                   y: Int(originFrame.origin.y * scale),
                                   width: _ow + 1,
                                   height: _oh + 1)
//        print(ofDelta)
        self.ox = oframe.origin.x
        self.oy = oframe.origin.y
        self.ow = oframe.size.width
        self.oh = oframe.size.height
        self.scale = scale
        self.size = size
        self.scaledSize = size * scale
        
        self.ax = (CGFloat(col) + 0.5) * size - ox * scale
        self.ay = (CGFloat(row) + 0.5) * size - oy * scale
        self.a = CGPoint(x: ax, y: ay)
        
        if !fixed {
            if let r = PieceRotation(rawValue: Int(arc4random() % 4)) {
                self.rotation = r
            }
        }
    }
}
