//  PieceGroup.swift
//  Created by Vladimir Roganov on 01.05.17.

import Foundation
import CoreGraphics

class PieceGroup {
    
    let uid: String
    var isLocked = false {
        didSet {
            self.pieces.forEach { (p) in
                p.item.locked = self.isLocked
                p.layer.zPosition = 0
            }
        }
    }
    var pieces: [Piece]
    
    func unsub() {
        self.pieces.removeAll()
    }
    
    init(withPieces: [Piece]) {
        uid = UUID().uuidString
        pieces = withPieces
        pieces.forEach { (p) in
            p.group = self
        }
    }
    
    func showLockedEffect() {
        pieces.forEach { (p) in
            p.showLockedEffect()
        }
    }
    
    func hideLockedEffect() {
        pieces.forEach { (p) in
            p.hideLockedEffect()
        }
    }
    
    func updateZIndex() {
        var maxLastAction: CGFloat = 0.0
        for p in pieces {
            maxLastAction = max(maxLastAction, p.lastAction)
        }
        
        let s = isLocked ? 0 : maxLastAction - CGFloat(pieces.count * 500)
        for p in pieces {
            p.layer.zPosition = s
        }
    }
    
    func didRotatePiece(piece: Piece, to: PieceRotation) {
        let cx = piece.item.gridX
        let cy = piece.item.gridY
        for p in pieces {
            if p.isRotating && p != piece {
                // avoiding group rotation from multiple pieces
                return
            }
        }
        
        pieces.forEach { (p) in
            if p.item.uid != piece.item.uid {
                p.animateRotationFromPiece(piece, to: to, lx: cx, ly: cy)
            }
        }
        piece.animateRotationFromPiece(piece, to: to, lx: cx, ly: cy)
    }
    
    func didMovePiece(piece: Piece, by: CGPoint) {
        pieces.forEach { (p) in
            if p.item.uid != piece.item.uid {
                p.move(by: by)
            }
        }
    }
    
    func snapToGrid(piece: Piece) {
        pieces.forEach { (p) in
            if p.item.uid != piece.item.uid {
                p.snapToGrid(false, group: true)
            }
        }
        checkLocked()
    }
    
    func snapToGrid(piece: String, dx: Int, dy: Int) {
        pieces.forEach { (p) in
            if p.item.uid != piece {
                p.snapToGrid(dx: dx, dy: dy)
            }
        }
        checkLocked()
    }
    
    func checkLocked() {
        if let piece = pieces.first {
            if pieces.count > 6 {
                if piece.item.dx == 0
                    && piece.item.dy == 0
                    && piece.item.rotation == .origin {
                    isLocked = true
                }
            }
        }
    }
    
    func append(piece: Piece) {
        piece.group = self
        piece.item.locked = isLocked
        pieces.append(piece)
    }
    
    func combine(withGroup: PieceGroup) -> PieceGroup {
        if pieces.count > withGroup.pieces.count {
            pieces.append(contentsOf: withGroup.pieces)
            withGroup.pieces.forEach({ (p) in
                p.group = self
                p.item.locked = self.isLocked
            })
            return withGroup
        } else {
            withGroup.pieces.append(contentsOf: pieces)
            pieces.forEach({ (p) in
                p.group = withGroup
            })
            return self
        }
    }
    
    func containsPiece(_ piece: Piece) -> Bool {
        return pieces.contains(piece)
    }
}
