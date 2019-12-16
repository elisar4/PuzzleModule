//  SKPiece.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

//class Emboss

class SKPiece: SKSpriteNode, PieceItemOut {
    
    var psize: CGSize {
        get {
            return size
        }
        set {
            self.size = newValue
        }
    }
    
    var point: CGPoint {
        get {
            if let container = parent {
                return CGPoint(x: position.x, y: container.frame.size.height - position.y)
            }
            return CGPoint(x: position.x, y: -position.y)
        }
        set {
            if let container = parent {
                position = CGPoint(x: newValue.x, y: container.frame.size.height - newValue.y)
            } else {
                position = CGPoint(x: newValue.x, y: -newValue.y)
            }
        }
    }
    
    public func unsub() {
        item.output = nil
        group = nil
        removeFromParent()
    }
    
    static var nextLastAction: CGFloat = 50000.0
    static func getNextLastAction() -> CGFloat {
        Piece.nextLastAction += 0.1
        return Piece.nextLastAction
    }
    
    let item: PieceItem
    
    var group: PieceGroup?
    var output: PieceOutput?
    
    var isRotating = false
    var isMoving = false
    var lastAction: CGFloat = 0.0
    
    var rotation: PieceRotation = .origin {
        didSet {
            if item.rotation.angle < 0 && rotation.angle > 0 {
                zRotation = CGFloat.pi - zRotation
            }
            item.rotation = rotation
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
        let dur = animated ? 0.15 : 0.0
        rotation = to
        isRotating = false
        let action = SKAction.rotate(toAngle: rotation.angle, duration: dur)
        run(action) {
            //self.output?.didRotate(piece: self)
            self.isRotating = false
        }
    }
    
    func animateRotationFromPiece(_ piece: Piece, to: PieceRotation, lx: Int, ly: Int) {
        
//            let oldT = layer.transform
//            let oldAnchor = mAnchor
//
//            let ap = convert(piece.item.a, from: piece)
//            mAnchor = CGPoint(x: ap.x / (frame.width), y: ap.y / (frame.height))
//
//            UIView.animate(withDuration: 0.25, animations: {
//                self.layer.transform = CATransform3DRotate(CATransform3DIdentity, PieceRotation.right.angle, 0.0, 0.0, 1.0)
//            }) { (finished) in
//                self.mAnchor = oldAnchor
//
//                CATransaction.instant {
//                    self.layer.transform = oldT
//                    self.rotation = to
//                    if self == piece {
//                        self.item.gridX = lx
//                        self.item.gridY = ly
//                    } else {
//                        let ldx = self.item.col - piece.item.col
//                        let ldy = self.item.row - piece.item.row
//                        if to == .right {
//                            self.item.gridX = lx + ldy
//                            self.item.gridY = ly - ldx
//                        } else if to == .upside {
//                            self.item.gridX = lx - ldx
//                            self.item.gridY = ly - ldy
//                        } else if to == .left {
//                            self.item.gridX = lx - ldy
//                            self.item.gridY = ly + ldx
//                        } else if to == .origin {
//                            self.item.gridX = lx + ldx
//                            self.item.gridY = ly + ldy
//                        }
//                    }
//                }
//                self.isRotating = false
//
//                if piece == self {
//                    self.output?.didRotate(piece: self)
//                }
//            }
    }
    
    func canGroup(withPiece piece: Piece) -> Bool {
        if piece.item.uid == item.uid {
            return false
        }
        
        if piece.rotation != rotation {
            return false
        }
        
//        if piece.group?.containsPiece(self) ?? false {
//            return false
//        }
        return item.canGroup(withItem: piece.item, atRotation: rotation)
    }
    
    init(withItem item: PieceItem, originImage: UIImage) {
        self.item = item
        
        var trans = CGAffineTransform(translationX: item.oframe.origin.x, y: item.oframe.origin.y).scaledBy(x: item.scale, y: item.scale).translatedBy(x: -item.oframe.origin.x, y: -item.oframe.origin.y)
        let p = item.path.copy(using: &trans)!
        var t = CGAffineTransform(translationX: -item.oframe.origin.x, y: -item.oframe.origin.y)
        
        let cgi = originImage.cgImage!
        let im = cgi.cropping(to: item.oframeScaled)!
        
        let image = UIImage(cgImage: im).croppedWith(path: p.copy(using: &t)!)!
        
        let s = item.oframeScaled.size
        
        super.init(texture: SKTexture(image: image), color: .clear, size: s)
        let sh2 = """
void main() {
    vec4 current_color = SKDefaultShading();
    if (current_color.a > 0.0) {
        // Normalized pixel coordinates (from 0 to 1)
        vec2 uv = gl_FragCoord.xy/a_size;

        // Time varying pixel color
        vec3 col = 0.5 + 0.5*cos(u_time+uv.xyx+vec3(0,2,4));

        // Output to screen
        gl_FragColor = vec4(col,1.0);
    } else {
       // use the current (transparent) color
       gl_FragColor = current_color;
   }
}
"""
        let sh = """
void main() {
    // find the current pixel color
    vec4 current_color = SKDefaultShading();

    // if it's not transparent
    if (current_color.a > 0.0) {
        // find the size of one pixel by reading the input size
        vec2 pixel_size = 0.7 / a_size;

        // copy our current color so we can modify it
        vec4 new_color = current_color;

        // move up one pixel diagonally and read the current color, multiply it by the input strength, then add it to our pixel color
        new_color += texture2D(u_texture, v_tex_coord - pixel_size) * u_strength;

        // move down one pixel diagonally and read the current color, multiply it by the input strength, then subtract it to our pixel color
        new_color -= texture2D(u_texture, v_tex_coord + pixel_size) * u_strength;

        // use that new color, with an alpha of 1, for our pixel color, multiplying by this pixel's alpha
        // (to avoid a hard edge) and also multiplying by the alpha for this node
        gl_FragColor = vec4(new_color.rgb, 1) * current_color.a * v_color_mix.a;
    } else {
        // use the current (transparent) color
        gl_FragColor = current_color;
    }
}
"""
        
        let shadow = SKShader(source: sh2, uniforms: [
            SKUniform(name: "u_strength", float: 0.35)
        ])
        if #available(iOS 9.0, *) {
            shadow.attributes = [SKAttribute(name: "a_size", type: .vectorFloat2)]
        }
        shader = shadow

        let spriteSize = vector_float2(Float(s.width), Float(s.height))
        if #available(iOS 10.0, *) {
            setValue(SKAttributeValue(vectorFloat2: spriteSize), forAttribute: "a_size")
        }
        
        anchorPoint = CGPoint(x: 0 + item.ax / s.width, y: 1 - item.ay / s.height)
        
        rotation = item.rotation
        
        item.output = self
        
        item.snapToOriginGridCell()
        
        updateLastAction()
    }
    
    func tap() {
        if item.fixed {
            //return
        }
        if group?.isLocked ?? false {
            return
        }
        if isRotating || isMoving {
            return
        }
        isRotating = true
        updateLastAction()

        if let gr = group {
            print(gr)
            //gr.didRotatePiece(piece: self, to: rotation.nextSide)
        } else {
            rotate(to: rotation.nextSide)
        }
    }
    
    func updateLastAction() {
        lastAction = Piece.getNextLastAction()
    }
    
    var isGroupLocked: Bool {
        return group?.isLocked ?? false
    }
    
    var canPan: Bool {
        return !isRotating
    }

    func beginPan() {
        if isGroupLocked {
            UIView.animate(withDuration: 0.2,
                           animations: {
                self.group?.showLockedEffect()
            })
            return
        }
        output?.pickSingleEvent()
        updateLastAction()
        zPosition = 1500000.0
        group?.pieces.forEach({ (p) in
            p.layer.zPosition = 1500000.0
        })
        if group == nil {
//            output?.didPickSinglePiece(self)
        }
    }
    
    func movePan(_ translation: CGPoint) {
        if isGroupLocked {
            return
        }

        self.move(by: translation)

        //self.group?.didMovePiece(piece: self, by: translation)

        if self.group == nil {
            //self.output?.didMoveSinglePiece(self)
        }
    }
    
    func endPan() {
        if isGroupLocked {
            UIView.animate(withDuration: 0.2,
                           animations: {
                self.group?.hideLockedEffect()
            })
            return
        }
        output?.dropSingleEvent()
        if group == nil {
//            if output?.didDropSinglePiece(self) ?? false {
//                return
//            }
        }
        
        isMoving = true

        let LGX = item.gridX
        let LGY = item.gridY
        let gr = group

        let translation = output?.correctedSnapPoint(forPiece: self) ?? item.deltaXY(x: item.nearestGX, y: item.nearestGY)
        let delta = moveDelta(by: translation)
        let action = SKAction.moveBy(x: delta.x, y: delta.y, duration: 0.15)
        //+++++++://gr?.didMovePiece(piece: self, by: translation)//
        
        run(action) {
            self.isMoving = false
            self.item.snapToNearestGridCell()
            let dx = self.item.gridX - LGX
            let dy = self.item.gridY - LGY
            gr?.snapToGrid(piece: self.item.uid, dx: dx, dy: dy)
            self.dispatchSnap()
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
    
    func move(by: CGPoint) {
        isMoving = true
        position = CGPoint(x: position.x + by.x, y: position.y - by.y)
    }
    
    private func moveDelta(by: CGPoint) -> CGPoint {
        let newP = CGPoint(x: position.x + by.x, y: position.y - by.y)
        return CGPoint(x: newP.x - position.x, y: newP.y - position.y)
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
        //output?.didSnap(piece: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
