//  Unused.swift
//  Created by Vladimir Roganov on 06/12/2018.

import Foundation


//func clearBoard() {
//    for p in pcs {
//        p.removeFromSuperview()
//    }
//    pcs.removeAll()
//    gr.removeAll()
//}
//
//func resetPuzzleRequest() {
//    clearBoard()
//    configure(withPaths: lastPaths, frames: lastFrames, image: lastImage, difficulty: lastDifficulty, originSize: lastSize, w: lastW, h: lastH, puzzleState: nil, shuffle: lastShuffled, boardBGColor: lastBoardBG, paletteBGColor: lastPaletteBG)
//}
//
//func preloadPieceItems() {
//    var col = 0
//    var row = 0
//    while let nxt = getNextUncompletedRowCol(fromCol: col, fromRow: row) {
//        col = nxt.0
//        row = nxt.1
//        let items = self.lastDataSource.getPieceItems(forBoardColumn: col,
//                                                      boardRow: row)
//
//        for item in items {
//            _ = self.lastDataSource.getPiece(forItem: item)
//        }
//    }
//}
