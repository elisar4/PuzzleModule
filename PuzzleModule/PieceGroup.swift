//  PieceGroup.swift
//  Created by Vladimir Roganov on 01.05.17.

import Foundation
import CoreGraphics

class PieceGroup
{
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
    
    func unsub()
    {
        self.pieces.removeAll()
    }
    
    init(withPieces: [Piece])
    {
        self.uid = UUID().uuidString
        self.pieces = withPieces
        self.pieces.forEach { (p) in
            p.group = self
        }
    }
    
    func showLockedEffect()
    {
        self.pieces.forEach { (p) in
            p.showLockedEffect()
        }
    }
    
    func hideLockedEffect()
    {
        self.pieces.forEach { (p) in
            p.hideLockedEffect()
        }
    }
    
    func updateZIndex()
    {
        var maxLastAction: CGFloat = 0.0
        for p in self.pieces
        {
            maxLastAction = max(maxLastAction, p.lastAction)
        }
        
        let s = self.isLocked ? 0 : maxLastAction - CGFloat(self.pieces.count * 500)
        for p in self.pieces
        {
            p.layer.zPosition = s
        }
    }
    
    func didRotatePiece(piece: Piece, to: PieceRotation)
    {
        for p in self.pieces
        {
            if p.isRotating && p != piece
            {
                // avoiding group rotation from multiple pieces
                return
            }
        }
        
        self.pieces.forEach { (p) in
            if p.item.uid != piece.item.uid
            {
                p.animateRotationFromPiece(piece, to: to)
            }
        }
        piece.animateRotationFromPiece(piece, to: to)
    }
    
    func didMovePiece(piece: Piece, by: CGPoint)
    {
        self.pieces.forEach { (p) in
            if p.item.uid != piece.item.uid
            {
                p.move(by: by)
            }
        }
    }
    
    func snapToGrid(piece: Piece) {
        self.pieces.forEach { (p) in
            if p.item.uid != piece.item.uid {
                p.snapToGrid(false, group: true)
            }
        }
        self.checkLocked()
    }
    
    func snapToGrid(piece: String, dx: Int, dy: Int) {
        self.pieces.forEach { (p) in
            if p.item.uid != piece {
                p.snapToGrid(dx: dx, dy: dy)
            }
        }
        self.checkLocked()
    }
    
    func checkLocked() {
        if let piece = self.pieces.first {
            if self.pieces.count > 6 {
                if piece.item.dx == 0
                    && piece.item.dy == 0
                    && piece.item.rotation == .origin {
                    self.isLocked = true
                }
            }
        }
    }
    
    func append(piece: Piece) {
        piece.group = self
        piece.item.locked = self.isLocked
        self.pieces.append(piece)
    }
    
    func combine(withGroup: PieceGroup) -> PieceGroup
    {
        if self.pieces.count > withGroup.pieces.count
        {
            self.pieces.append(contentsOf: withGroup.pieces)
            withGroup.pieces.forEach({ (p) in
                p.group = self
                p.item.locked = self.isLocked
            })
            return withGroup
        } else
        {
            withGroup.pieces.append(contentsOf: self.pieces)
            self.pieces.forEach({ (p) in
                p.group = withGroup
            })
            return self
        }
    }
    
    func containsPiece(_ piece: Piece) -> Bool
    {
        return self.pieces.contains(piece)
    }
}
