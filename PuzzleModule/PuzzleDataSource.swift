//  PuzzleDataSource.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

class PuzzleDataSource {
    
    func unsub() {
        proxys.forEach({$0.img.image = nil})
        pcs.removeAll()
        proxys.removeAll()
        pcsItms.removeAll()
    }
    
    let difficulty: EAPuzzleDifficulty
    let boardSize: EAPuzzleBoard
    let puzzleImage: UIImage
    let originSize: CGFloat
    let scale: CGFloat
    
    var pcsItms: [PieceItem] = []
    var pcs: [Piece] = []
    var proxys: [PieceProxy] = []
    
    init(withPiecePaths paths: [[CGPath]],
         frames: [[CGRect]],
         difficulty: EAPuzzleDifficulty,
         scale: CGFloat,
         originSize: CGFloat,
         boardSize: EAPuzzleBoard,
         puzzleImage: UIImage) {
        self.scale = scale
        self.originSize = originSize
        self.difficulty = difficulty
        self.boardSize = boardSize
        self.puzzleImage = puzzleImage
        self.pcsItms = buildItems(withColumns: difficulty.width, rows: difficulty.height, scale: scale, originSize: originSize, rotation: difficulty.rotation, paths: paths, frames: frames)
    }
    
    func buildItems(withColumns columns: Int, rows: Int, scale: CGFloat, originSize: CGFloat, rotation: Bool, paths: [[CGPath]], frames: [[CGRect]]) -> [PieceItem] {
        let scaledSize = originSize * scale
        var pieceItems: [PieceItem] = []
        for r in 0..<rows {
            for c in 0..<columns {
                let name = "\(r)-\(c)"
                let path = paths[r][c]
                pieceItems.append(PieceItem(uid: name, row: r, col: c, path: path, scale: scale, size: scaledSize, fixed: !rotation, originFrame: frames[r][c]))
            }
        }
        return pieceItems
    }
    
    func getPieceItemImageViewProxy(pieceItem: PieceItem) -> UIImageView {
        if let p = proxys.first(where: {$0.uid == pieceItem.uidInt}) {
            return p.img
        }
        let proxy = PieceProxy(withItem: pieceItem, originImage: puzzleImage)
        proxy.uid = pieceItem.uidInt
        proxy.img.tag = pieceItem.uidInt
        proxys.append(proxy)
        return proxy.img
    }
    
    func getPiece(forItem: PieceItem) -> Piece {
        if let p = pcs.first(where: {$0.item.uid == forItem.uid}) {
            return p
        }
        let p = Piece(withItem: forItem, originImage: puzzleImage)
        pcs.append(p)
        return p
    }
    
    func getPieceItemsByPieceStates(_ states: [PieceState]) -> [PieceItem] {
        let ids = states.map({$0.uid})
        return pcsItms.filter({ids.contains($0.uid)})
    }
    
    func getPieceItemById(_ uid: String) -> PieceItem? {
        return pcsItms.first(where: {$0.uid == uid})
    }
    
    func getPieceItems(forBoardColumn c: Int, boardRow r: Int) -> [PieceItem] {
        let boundMNC = boardSize.verticalSize.width * c
        let boundMXC = boundMNC + boardSize.verticalSize.width
        let boundMNR = boardSize.verticalSize.height * r
        let boundMXR = boundMNR + boardSize.verticalSize.height
        //print(boundMNC, boundMXC, boundMNR, boundMXR)
        return pcsItms.filter({($0.col >= boundMNC && $0.col < boundMXC && $0.row >= boundMNR && $0.row < boundMXR)})
    }
}
