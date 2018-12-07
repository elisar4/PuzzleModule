//  PieceOutput.swift
//  Created by Vladimir Roganov on 06/12/2018.

import Foundation

protocol PieceOutput {
    func didMoveSinglePiece(_ piece: Piece)
    func didPickSinglePiece(_ piece: Piece)
    func didDropSinglePiece(_ piece: Piece) -> Bool
    func didSnap(piece: Piece)
    func didRotate(piece: Piece)
    func correctedSnapPoint(forPiece: Piece) -> CGPoint
}

extension PuzzleViewController: PieceOutput {
    
    func didDropSinglePiece(_ piece: Piece) -> Bool {
        let p = piece
        p.isUserInteractionEnabled = true
        
        if boardController.canPlacePieceOnBoard(p, isSingle: true) {
            view.window?.isUserInteractionEnabled = false
            
            //if piece on board -> insert piece on board view
            boardController.addPiece(p)
            if !pcs.contains(p) {
                pcs.append(p)
                p.output = self
            }
            paletteController.didGrabItem(p.item)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.08, execute: {
                self.view.window?.isUserInteractionEnabled = true
            })
            
            output?.didUpdate(progress: self.currentProgress)
            return false
        } else {
            //else -> return to palette
            print("did return")
            paletteController.didReturnToPalette(piece)
            output?.didUpdate(progress: self.currentProgress)
            return true
        }
    }
    
    func didMoveSinglePiece(_ piece: Piece) {
        paletteController.hoverPiece(piece)
    }
    
    func didPickSinglePiece(_ piece: Piece) {
        if let wnd = view.window,
            let pt = piece.superview?.convert(piece.center, to: wnd) {
            view.window?.addSubview(piece)
            piece.center = pt
        }
    }
    
    func processGroup(_ piece: Piece) {
        let maxDist = (lastDataSource.originSize * lastDataSource.scale) * 3
        var shouldRepeat = false
        for p in pcs {
            let dist = piece.center.distance(toPoint: p.center)
            if dist > maxDist {
                continue
            }
            if piece.canGroup(withPiece: p) {
                if let gr1 = piece.group {
                    if let gr2 = p.group {
                        let removedGroup = gr1.combine(withGroup: gr2)
                        if let ind = gr.index(where: { $0.uid == removedGroup.uid }) {
                            gr.remove(at: ind)
                        }
                        shouldRepeat = true
                    } else {
                        gr1.append(piece: p)
                        shouldRepeat = true
                    }
                } else if let gr2 = p.group {
                    gr2.append(piece: piece)
                    shouldRepeat = true
                } else {
                    gr.append(PieceGroup(withPieces: [piece, p]))
                    shouldRepeat = true
                }
            }
        }
        
        if shouldRepeat {
            processGroup(piece)
        } else {
            output?.didUpdate(progress: currentProgress)
        }
    }
    
    func updateZIndexes() {
        for g in gr {
            g.updateZIndex()
        }
        
        let individualPieces = pcs.filter { $0.group == nil }
        for p in individualPieces {
            p.layer.zPosition = p.lastAction
        }
        
//        let zSorted = pcs.sorted { $0.layer.zPosition < $1.layer.zPosition }
//        for ps in zSorted {
//            boardController.view.bringSubviewToFront(ps)
//        }
    }
    
    func didSnap(piece: Piece) {
        processGroup(piece)
        //        for p in self.pcs
        //        {
        //            self.processGroup(p)
        //        }
        updateZIndexes()
        piece.group?.checkLocked()
        
        if gr.count == 1 {
            if gr[0].isLocked {
                if paletteController.data.count == 0 {
                    if pcs.count == gr[0].pieces.count {
                        let items = lastDataSource.getPieceItems(forBoardColumn: boardController.col, boardRow: boardController.row)
                        if boardController.isAllItemsOnBoard(items) {
                            if sectionTransition {
                                return;
                            }
                            sectionTransition = true
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.2,
                                                          execute: {
                                                            self.didCompleteSection()
                            })
                        }
                    }
                }
            }
        }
    }
    
    func didRotate(piece: Piece) {
        for p in pcs {
            processGroup(p)
        }
        updateZIndexes()
    }
    
    func correctedSnapPoint(forPiece piece: Piece) -> CGPoint {
        let corr = boardController.corrected(col: piece.item.nearestGX,
                                             row: piece.item.nearestGY)
        return piece.item.deltaXY(x: corr.0, y: corr.1)
    }
}
