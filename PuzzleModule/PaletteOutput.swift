//  PaletteOutput.swift
//  Created by Vladimir Roganov on 06/12/2018.

import UIKit

protocol PaletteOutput: class {
    func getProxy(fromItem: PieceItem) -> UIImageView
    func getProxyAsync(fromItem: PieceItem, completion: @escaping (UIImageView)->())
    func didPick(pieceItem: PieceItem, atPoint: CGPoint)
    func didMove(pieceItem: PieceItem, by: CGPoint)
    func didDrop(pieceItem: PieceItem, atPoint: CGPoint)
}

extension PuzzleViewController: PaletteOutput {
    
    func getProxy(fromItem: PieceItem) -> UIImageView {
        return lastDataSource.getPieceItemImageViewProxy(pieceItem: fromItem)
    }
    
    func getProxyAsync(fromItem: PieceItem, completion: @escaping (UIImageView) -> ()) {
        DispatchQueue.main.async {
            completion(self.lastDataSource.getPieceItemImageViewProxy(pieceItem: fromItem))
        }
    }
    
    func didPick(pieceItem: PieceItem, atPoint: CGPoint) {
//        let p = lastDataSource.getPiece(forItem: pieceItem)
//        if p.superview == nil {
//            view.window?.addSubview(p)
//        }
//        p.isUserInteractionEnabled = false
//        p.isHidden = false
//
//        if let pt = view.window?.convert(atPoint, from: paletteController.view) {
//            p.mAnchor = CGPoint(x: 0.5, y: 0.5)
//            p.rotation = pieceItem.rotation
//            p.center = pt
//        }
//        output?.pickPiece()
    }
    
    func didMove(pieceItem: PieceItem, by: CGPoint) {
//        let p = lastDataSource.getPiece(forItem: pieceItem)
//        p.center = CGPoint(x: p.center.x + by.x,
//                           y: p.center.y + by.y)
//        paletteController.hoverPiece(p)
    }
    
    func didDrop(pieceItem: PieceItem, atPoint: CGPoint) {
//        let p = lastDataSource.getPiece(forItem: pieceItem)
//        p.isUserInteractionEnabled = true
//        let single = p.group == nil
//        if boardController.canPlacePieceOnBoard(p, isSingle: single, fromPalette: true) {
//            boardController.view.window?.isUserInteractionEnabled = false
//            //if piece on board -> insert piece on board view
//            paletteController.didGrabItem(pieceItem)
//            boardController.addPiece(p)
//            if !pcs.contains(p) {
//                pcs.append(p)
//                p.output = self
//            }
//            UIView.animate(withDuration: 0.12,
//                           animations: {
//                            p.snapToGrid(false)
//            }, completion: { (finished) in
//                if finished {
//                    DispatchQueue.main.async {
//                        p.dispatchSnap()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: {
//                            self.boardController.view.window?.isUserInteractionEnabled = true
//                        })
//                    }
//                }
//            })
//            output?.dropPiece()
//        } else {
//            //else -> return to palette
//            paletteController.didReturnToPalette(p)
//            output?.returnToPalette()
//        }
    }
}
