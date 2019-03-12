//  PuzzleDataSource.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

class PuzzleDataSource {
    
    func unsub() {
        proxys.forEach({$0.image = nil})
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
    var proxys: [UIImageView] = []
    
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
        self.pcsItms = self.buildItems(withColumns: difficulty.width, rows: difficulty.height, scale: scale, originSize: originSize, rotation: difficulty.rotation, paths: paths, frames: frames)
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
        if let p = proxys.first(where: {$0.tag == pieceItem.uidInt}) {
            return p
        }
        let i = getPieceItemImageProxy2(pieceItem: pieceItem)
        let img = UIImageView(image: i)
        img.tag = pieceItem.uidInt
        proxys.append(img)
        return img
    }
    
    func getPieceItemImageProxy2(pieceItem: PieceItem) -> UIImage? {
        return getPieceProxy(forItem: pieceItem).render
    }
    
    func getPieceItemImageProxy(pieceItem: PieceItem) -> UIImage? {
        return getPiece(forItem: pieceItem).render
    }
    
    func getPieceItemProxy(pieceItem: PieceItem) -> UIView? {
        let p = getPiece(forItem: pieceItem)
        let v = p.img.snapshotView(afterScreenUpdates: true)
        v?.layer.transform = p.img.layer.transform
        return v
    }
    
    func getPiece(forItem: PieceItem) -> Piece {
        if let p = pcs.first(where: {$0.item.uid == forItem.uid}) {
            return p
        }
        let p = Piece(withItem: forItem, originImage: puzzleImage)
        pcs.append(p)
        return p
    }
    
    func getPieceProxy(forItem: PieceItem) -> PieceProxy {
        return PieceProxy(withItem: forItem, originImage: puzzleImage)
    }
    
    func getPieces(forItems: [PieceItem]) -> [Piece] {
        return forItems.map({ self.getPiece(forItem: $0) })
    }
    
    func getPieceItemsByPieceStates(_ states: [PieceState]) -> [PieceItem] {
        return getPieceItemsByIds(states.map({$0.uid}))
    }
    
    func getPieceItemsByIds(_ ids: [String]) -> [PieceItem] {
        return pcsItms.filter({ (itm) -> Bool in
            return ids.contains(itm.uid)
        })
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
        return pcsItms.filter { (item) -> Bool in
            return (item.col >= boundMNC && item.col < boundMXC
                    && item.row >= boundMNR && item.row < boundMXR)
        }
    }
}
