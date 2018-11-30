//  BoardViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

protocol BoardInput: class
{
    func setBoardPosition(col: Int, row: Int, isColLast: Bool, isRowLast: Bool, puzzleW: Int, puzzleH: Int, animated: Bool, completion: (()->())?)
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat)
    func addPiece(_ piece: Piece)
    func canPlacePieceOnBoard(_ piece: Piece) -> Bool
    func setFinishedState(withCompletion: (()->())?)
    func panTouchingPiece(_ pan: UIPanGestureRecognizer) -> Piece?
    func setBoardBGColor(_ color: UIColor)
}

class BoardViewController: UIViewController, BoardInput
{
    
    func unsub()
    {
        self.bgimg.image = nil
        self.bgimg.removeFromSuperview()
    }
    
    var board: EAPuzzleBoard?
    var originSize: CGFloat = 0.0
    
    var bgimg = UIImageView()
    
    var border = CAShapeLayer()
    
    var col: Int = -1
    var row: Int = -1
    
    var animating: Bool = false
    
    let pieceContainer: UIView = UIView()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.border.strokeColor = UIColor(white: 1.0, alpha: 0.0).cgColor
        self.border.fillColor = UIColor.clear.cgColor
        self.border.lineWidth = 7.5
        
        self.view.clipsToBounds = true
        self.bgimg.mAnchor = CGPoint.zero
        self.bgimg.contentMode = .scaleAspectFill
        self.bgimg.clipsToBounds = false
        self.bgimg.alpha = 0.0
        self.pieceContainer.mAnchor = CGPoint.zero
        self.pieceContainer.layer.addSublayer(self.border)
        self.view.backgroundColor = UIColor(white: 80.0/255.0, alpha: 1.0)
        self.view.addSubview(self.bgimg)
        self.view.addSubview(self.pieceContainer)

        self.pieceContainer.frame = CGRect(x: 0, y: 0,
                                           width: 3800,
                                           height: 3800)
    }
    
    func setBoardBGColor(_ color: UIColor)
    {
        self.view.backgroundColor = color
    }
    
    func panTouchingPiece(_ pan: UIPanGestureRecognizer) -> Piece?
    {
        if pan.state == .began
        {
            let pieces = self.pieceContainer.subviews.map({ (v) -> Piece? in
                if let p = v as? Piece
                {
                    return p
                }
                return nil
            })
            
            let pps = pieces.sorted(by: { (p1, p2) -> Bool in
                return p1?.layer.zPosition ?? 0 > p2?.layer.zPosition ?? 0
            })
            
            for p in pps
            {
                if let pp = p
                {
                    let pt = pan.location(in: pp)
                    if pp.hitTest(pt, with: nil) != nil
                    {
                        return pp
                    }
                }
            }
        }
        return nil
    }
    
    func isAllItemsOnBoard(_ items: [PieceItem]) -> Bool
    {
        let uids = self.pieceContainer.subviews.map { (v) -> String in
            if let p = v as? Piece
            {
                return p.item.uid
            }
            return ""
        }
        
        for item in items
        {
            if !uids.contains(item.uid)
            {
                return false
            }
        }
        
        return true
    }
    
    func addPiece(_ piece: Piece)
    {
        self.pieceContainer.addSubview(piece)
    }
    
    func removePiece(_ piece: Piece)
    {
        piece.removeFromSuperview()
    }
    
    func setBoardImageVisible(_ val: Bool)
    {
        self.bgimg.isHidden = !val
    }
    
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat)
    {
        self.board = boardSize
        self.originSize = originSize
    }
    
    
    var maxCol: Int = 0
    var maxRow: Int = 0
    
    func setBackgroundImage(_ image: UIImage, withMaxCols: Int, maxRows: Int)
    {
        self.maxCol = withMaxCols
        self.maxRow = maxRows
        
        let mx = CGFloat(withMaxCols) * originSize
        let my = CGFloat(maxRows) * originSize
        
        self.bgimg.frame = CGRect(x: 0, y: 0, width: mx, height: my)
        self.bgimg.image = image
        
        
        self.pieceContainer.frame = CGRect(x: 0, y: 0,
                                           width: mx,
                                           height: my)
        
        self.border.path = UIBezierPath(rect: self.bgimg.frame.insetBy(dx: 4, dy: 4)).cgPath
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
        let maxBC = min(minBC + bw, maxCol)
        let minBR = bh * self.row
        let maxBR = min(minBR + bh, maxRow)
        
        if col >= minBC && col < maxBC
            && row >= minBR && row < maxBR
        {
            return true
        }
        
        return false
    }
    
    func setBoardPosition(col: Int, row: Int,
                          isColLast: Bool, isRowLast: Bool,
                          puzzleW: Int, puzzleH: Int,
                          animated: Bool = true, completion: (()->())? = nil)
    {
        if self.col == col && self.row == row
        {
            return;
        }
        
        print("\(self.col),\(self.row)==>\(col),\(row)")
        
        if self.animating
        {
            return;
        }
        
        self.animating = true
        
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
            if isRowFirst && isRowLast
            {
                yOff += -self.originSize * 0.25 + self.view.bounds.height * 0.5 - self.originSize * CGFloat(puzzleH) * 0.5
            } else
            {
                // correction, not all pieces available
                yOff += self.originSize * CGFloat(bh - dr)
            }
        }
        
        let cp = CGPoint(x: -CGFloat(bw * col) * self.originSize + xOff,
                         y: -CGFloat(bh * row) * self.originSize + yOff)
        
        self.col = col
        self.row = row
        
        self.bgimg.alpha = 0.15
        
        if animated
        {
            let mpcx = self.view.bounds.width * 0.5
            let mpcy = self.view.bounds.height * 0.5
            
            let mpc = self.pieceContainer.convert(CGPoint(x: mpcx, y: mpcy), from: self.view)
            let mpci = self.bgimg.convert(CGPoint(x: mpcx, y: mpcy), from: self.view)
            
            self.pieceContainer.mAnchorXY = mpc
            self.bgimg.mAnchorXY = mpci
            
            //first phase
            UIView.animate(withDuration: 0.6, delay: 0.05, options: [.curveEaseInOut], animations: {
                //anims 1
                self.pieceContainer.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.bgimg.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                
            }, completion: { (finished) in
                if finished
                {
                    self.pieceContainer.mAnchor = CGPoint.zero
                    self.bgimg.mAnchor = CGPoint.zero
                    
                    //second phase
                    UIView.animate(withDuration: 0.9, delay: 0.11, options: [.curveEaseInOut], animations: {
                        //anims2
                        
                        self.pieceContainer.transform = CGAffineTransform.identity
                        self.bgimg.transform = CGAffineTransform.identity
                        self.pieceContainer.center = cp
                        self.bgimg.center = cp
                        
                    }, completion: { (finished) in
                        if finished
                        {
                            self.animating = false
                            completion?()
                        }
                    })
                }
            })
        } else
        {
            self.pieceContainer.center = cp
            self.bgimg.center = cp
            self.animating = false
        }
        
        self.border.strokeColor = UIColor(white: 1.0, alpha: 0.25).cgColor
    }
    
    func setFinishedState(withCompletion: (()->())?)
    {
        let cx = self.view.bounds.width * 0.5
        let cy = self.view.bounds.height * 0.5
        let scale = self.view.bounds.width / self.bgimg.bounds.width
        
        let anch = CGPoint(x: 0.5, y: 0.5)
        
        self.pieceContainer.mAnchor = anch
        self.bgimg.mAnchor = anch
        
        UIView.animate(withDuration: 0.8, delay: 0.0, options: [], animations: {
            
            self.pieceContainer.center = CGPoint(x: cx, y: cy)
            self.bgimg.center = CGPoint(x: cx, y: cy)
            
            self.pieceContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.bgimg.transform = CGAffineTransform(scaleX: scale, y: scale)
            
        }) { (finished) in
            if finished
            {
                withCompletion?()
            }
        }
    }
}
