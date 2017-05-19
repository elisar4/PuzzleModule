//  BoardViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

protocol BoardOutput: class
{
    
}

protocol BoardInput: class
{
    func setBoardPosition(col: Int, row: Int, isColLast: Bool, isRowLast: Bool, puzzleW: Int, puzzleH: Int)
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat)
    func addPiece(_ piece: Piece)
    func canPlacePieceOnBoard(_ piece: Piece) -> Bool
}

class BoardViewController: UIViewController, BoardInput
{
    weak var output: BoardOutput?
    
    var board: EAPuzzleBoard?
    var originSize: CGFloat = 0.0
    
    var col: Int = 0
    var row: Int = 0
    
    let pieceContainer: UIView = UIView()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.clipsToBounds = true
        self.pieceContainer.mAnchor = CGPoint.zero
        self.pieceContainer.backgroundColor = UIColor(white: 80.0/255.0, alpha: 1.0)
        self.view.addSubview(self.pieceContainer)

        self.pieceContainer.frame = CGRect(x: 0, y: 0,
                                           width: 3800,
                                           height: 3800)
        print("board did load")
    }
    
    func addPiece(_ piece: Piece)
    {
        self.pieceContainer.addSubview(piece)
    }
    
    func removePiece(_ piece: Piece)
    {
        piece.removeFromSuperview()
    }
    
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat)
    {
        self.board = boardSize
        self.originSize = originSize
    }
    
    func canPlacePieceOnBoard(_ piece: Piece) -> Bool
    {
        if let sv = piece.superview
        {
            let pt = self.pieceContainer.convert(piece.center, from: sv)
            if let v = self.pieceContainer.hitTest(pt, with: nil)
            {
                if v.isDescendant(of: self.pieceContainer)
                {
                    let oldCenter = piece.center
                    piece.center = pt
                    let ngx = piece.item.nearestGX
                    let ngy = piece.item.nearestGY
                    if self.isColRowInside(col: ngx, row: ngy)
                    {
                        return true
                    }
                    piece.center = oldCenter
                }
            }
        }
        return false
    }
    
    func isColRowInside(col: Int, row: Int) -> Bool
    {
        let bw = self.board?.verticalSize.width ?? 0
        let bh = self.board?.verticalSize.height ?? 0
        
        let minBC = bw * self.col
        let maxBC = minBC + bw
        let minBR = bh * self.row
        let maxBR = minBR + bh
        
        if col >= minBC && col < maxBC
            && row >= minBR && row < maxBR
        {
            return true
        }
        
        return false
    }
    
    func setBoardPosition(col: Int, row: Int,
                          isColLast: Bool, isRowLast: Bool,
                          puzzleW: Int, puzzleH: Int)
    {
        let bw = self.board?.verticalSize.width ?? 0
        let bh = self.board?.verticalSize.height ?? 0
        
        let isColFirst = col == 0
        let isRowFirst = row == 0
        
        var xOff = self.originSize * 0.25
        var yOff = self.originSize * 0.25
        
        if isColFirst && isColLast
        {
            //is first and last
            xOff = self.originSize * 0.25
        } else if isColFirst
        {
            //first and more
            xOff = 0
        } else if isColLast
        {
            //last
            xOff = self.originSize * 0.5
        }
        
        if isRowFirst && isRowLast
        {
            //is first and last
            yOff = self.originSize * 0.25
        } else if isRowFirst
        {
            //first and more
            yOff = 0
        } else if isRowLast
        {
            //last
            yOff = self.originSize * 0.5
        }
        
        let dc = puzzleW - bw * col
        if dc < bw
        {
            // correction, not all pieces available
            xOff += self.originSize * CGFloat(bw - dc)
        }
        
        let dr = puzzleH - bh * row
        if dr < bh
        {
            // correction, not all pieces available
            yOff += self.originSize * CGFloat(bh - dr)
        }
        
        self.pieceContainer.center = CGPoint(x: -CGFloat(bw * col) * self.originSize + xOff,
                                             y: -CGFloat(bh * row) * self.originSize + yOff)
        
        self.col = col
        self.row = row
    }
    
    func isLastCol(_ col: Int) -> Bool
    {
        
        return false
    }
    
}
