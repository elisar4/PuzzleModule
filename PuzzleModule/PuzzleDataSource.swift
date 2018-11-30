//  PuzzleDataSource.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

class PuzzleDataSource
{
    func unsub()
    {
        self.proxys.forEach { (im) in
            im.image = nil
        }
        
        self.pcs.removeAll()
        self.proxys.removeAll()
        self.pcsItms.removeAll()
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
         puzzleImage: UIImage)
    {
        self.scale = scale
        self.originSize = originSize
        self.difficulty = difficulty
        self.boardSize = boardSize
        self.puzzleImage = puzzleImage
        self.pcsItms = self.buildItems(withColumns: difficulty.width, rows: difficulty.height, scale: scale, originSize: originSize, rotation: difficulty.rotation, paths: paths, frames: frames)
    }
    
    func buildItems(withColumns columns: Int, rows: Int, scale: CGFloat, originSize: CGFloat, rotation: Bool, paths: [[CGPath]], frames: [[CGRect]]) -> [PieceItem]
    {
        let scaledSize = originSize * scale
        var pieceItems: [PieceItem] = []
        for r in 0..<rows
        {
            for c in 0..<columns
            {
                let name = "\(r)-\(c)"
                let path = paths[r][c]
                pieceItems.append(PieceItem(uid: name, row: r, col: c, path: path, scale: scale, size: scaledSize, fixed: !rotation, originFrame: frames[r][c]))
            }
        }
        return pieceItems
    }
    
    func getPieceItemImageViewProxy(pieceItem: PieceItem) -> UIImageView
    {
        if let p = self.proxys.filter({$0.tag == pieceItem.uidInt}).first
        {
            return p
        }
        let i = self.getPieceItemImageProxy2(pieceItem: pieceItem)
        let img = UIImageView(image: i)
        img.tag = pieceItem.uidInt
        self.proxys.append(img)
        //img.mAnchor = CGPoint.zero
        //img.transform = pieceItem.rotationTransform
        return img
    }
    
    func getPieceItemImageProxy2(pieceItem: PieceItem) -> UIImage?
    {
        let p = getPieceProxy(forItem: pieceItem)
        return p.render
    }
    
    func getPieceItemImageProxy(pieceItem: PieceItem) -> UIImage?
    {
        let p = getPiece(forItem: pieceItem)
        return p.render
    }
    
    func getPieceItemProxy(pieceItem: PieceItem) -> UIView?
    {
        let p = getPiece(forItem: pieceItem)
        let v = p.img.snapshotView(afterScreenUpdates: true)
        v?.layer.transform = p.img.layer.transform
        return v
    }
    
    func getPiece(forItem: PieceItem) -> Piece
    {
        if let p = self.pcs.filter({$0.item.uid == forItem.uid}).first
        {
            return p
        }
        let p = Piece(withItem: forItem, originImage: self.puzzleImage)
        self.pcs.append(p)
        return p
    }
    
    func getPieceProxy(forItem: PieceItem) -> PieceProxy
    {
        let p = PieceProxy(withItem: forItem, originImage: self.puzzleImage)
        return p
    }
    
    func getPieces(forItems: [PieceItem]) -> [Piece]
    {
        return forItems.map({ self.getPiece(forItem: $0) })
    }
    
    func getPieceItemsByPieceStates(_ states: [PieceState]) -> [PieceItem]
    {
        let ids = states.map { (ps) -> String in
            return ps.uid
        }
        return self.getPieceItemsByIds(ids)
    }
    
    func getPieceItemsByIds(_ ids: [String]) -> [PieceItem]
    {
        var data: [PieceItem] = []
        for uid in ids
        {
            let item = self.pcsItms.filter({ (itm) -> Bool in
                return itm.uid == uid
            })
            if let i = item.first
            {
                data.append(i)
            }
        }
        return data
    }
    
    func getPieceItemById(_ uid: String) -> PieceItem?
    {
        let item = self.pcsItms.filter({ (itm) -> Bool in
            return itm.uid == uid
        })
        if let i = item.first
        {
            return i
        }
        return nil
    }
    
    func getPieceItems(forBoardColumn c: Int, boardRow r: Int) -> [PieceItem]
    {
        let boundMNC = boardSize.verticalSize.width * c
        let boundMXC = boundMNC + boardSize.verticalSize.width
        let boundMNR = boardSize.verticalSize.height * r
        let boundMXR = boundMNR + boardSize.verticalSize.height
        print(boundMNC, boundMXC, boundMNR, boundMXR)
        let data = self.pcsItms.filter { (item) -> Bool in
            return (item.col >= boundMNC
                && item.col < boundMXC
                && item.row >= boundMNR
                && item.row < boundMXR)
        }
        return data
    }
}
