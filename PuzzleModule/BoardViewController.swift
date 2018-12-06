//  BoardViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

protocol BoardInput: class {
    func setBoardPosition(col: Int, row: Int, isColLast: Bool, isRowLast: Bool, puzzleW: Int, puzzleH: Int, animated: Bool, completion: (()->())?)
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat)
    func addPiece(_ piece: Piece)
    func canPlacePieceOnBoard(_ piece: Piece, isSingle: Bool, fromPalette: Bool) -> Bool
    func setFinishedState(withCompletion: (()->())?)
    func panTouchingPiece(_ pan: UIPanGestureRecognizer) -> Piece?
    func setBoardBGColor(_ color: UIColor)
}

class BoardViewController: UIViewController, BoardInput {
    
    func unsub() {
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
    
    override func viewDidLoad() {
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
    
    func setBoardBGColor(_ color: UIColor) {
        self.view.backgroundColor = color
    }
    
    func panTouchingPiece(_ pan: UIPanGestureRecognizer) -> Piece? {
        if pan.state == .began {
            let pieces = self.pieceContainer.subviews.map({ (v) -> Piece? in
                if let p = v as? Piece {
                    return p
                }
                return nil
            })
            
            let pps = pieces.sorted(by: { (p1, p2) -> Bool in
                return p1?.layer.zPosition ?? 0 > p2?.layer.zPosition ?? 0
            })
            
            for p in pps {
                if let pp = p {
                    let pt = pan.location(in: pp)
                    if pp.hitTest(pt, with: nil) != nil {
                        return pp
                    }
                }
            }
        }
        return nil
    }
    
    func isAllItemsOnBoard(_ items: [PieceItem]) -> Bool {
        let uids = self.pieceContainer.subviews.map { (v) -> String in
            if let p = v as? Piece {
                return p.item.uid
            }
            return ""
        }
        
        for item in items {
            if !uids.contains(item.uid) {
                return false
            }
        }
        
        return true
    }
    
    func addPiece(_ piece: Piece) {
        self.pieceContainer.addSubview(piece)
    }
    
    func removePiece(_ piece: Piece) {
        piece.removeFromSuperview()
    }
    
    func setBoardImageVisible(_ val: Bool) {
        self.bgimg.isHidden = !val
    }
    
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat) {
        self.board = boardSize
        self.originSize = originSize
    }
    
    
    var maxCol: Int = 0
    var maxRow: Int = 0
    
    func setBackgroundImage(_ image: UIImage, withMaxCols: Int, maxRows: Int) {
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
    
    func snapPoint(_ piece: Piece) -> (Int, Int) {
        guard let sv = piece.superview else {
            return (-1, -1)
        }
        let pt = pieceContainer.convert(piece.center, from: sv)
        if let v = pieceContainer.hitTest(pt, with: nil) {
            if v.isDescendant(of: view) {
                
                let r = sv.convert(piece.frame, to: pieceContainer)
                
                let gxf = (r.origin.x + piece.item.ax) / originSize
                let ngx = (gxf < 0) ? Int(gxf - 0.5) : Int(gxf + 0.5)
                let gyf = (r.origin.y + piece.item.ay) / originSize
                let ngy = (gyf < 0) ? Int(gyf - 0.5) : Int(gyf + 0.5)
                
                return (ngx, ngy)
            }
        }
        return (-1, -1)
    }
    
    func canPlacePieceOnBoard(_ piece: Piece, isSingle: Bool = false, fromPalette: Bool = false) -> Bool {
        guard let sv = piece.superview else {
            return false
        }
        let pt = pieceContainer.convert(piece.center, from: sv)
        if let v = pieceContainer.hitTest(pt, with: nil) {
            if v.isDescendant(of: view) {
                
                let tp = view.convert(CGPoint(x: 0.0, y: view.frame.maxY), to: sv)
                if piece.frame.origin.y > tp.y {
                    return false
                }
                
                let r = sv.convert(piece.frame, to: pieceContainer)
                
                let gxf = (r.origin.x + piece.item.ax) / originSize
                let ngx = (gxf < 0) ? Int(gxf - 0.5) : Int(gxf + 0.5)
                let gyf = (r.origin.y + piece.item.ay) / originSize
                let ngy = (gyf < 0) ? Int(gyf - 0.5) : Int(gyf + 0.5)
                
                if self.isColRowInside(col: ngx, row: ngy) {
                    piece.frame = r
                    return true
                } else if isSingle && fromPalette {
                    let corr = self.corrected(col: ngx, row: ngy)
                    if corr.0 != ngx || corr.1 != ngy {
                        piece.frame = r
                        return true
                    }
                } else if isSingle {
                    let corr = self.corrected(col: ngx, row: ngy)
                    if corr.0 != ngx {
                        piece.frame = r
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func isColRowInside(col: Int, row: Int) -> Bool {
        let bw = self.board?.verticalSize.width ?? 0
        let bh = self.board?.verticalSize.height ?? 0
        
        let minBC = bw * self.col
        let maxBC = min(minBC + bw, maxCol)
        let minBR = bh * self.row
        let maxBR = min(minBR + bh, maxRow)
        
        if col >= minBC && col < maxBC
            && row >= minBR && row < maxBR {
            return true
        }
        
        return false
    }
    
    func corrected(_ piece: Piece) -> (Int, Int) {
        return snapPoint(piece)
    }
    
    func corrected(col: Int, row: Int) -> (Int, Int) {
        if isColRowInside(col: col, row: row) {
            return (col, row)
        }
        
        let bw = self.board?.verticalSize.width ?? 0
        let bh = self.board?.verticalSize.height ?? 0
        
        let minBC = bw * self.col
        let maxBC = min(minBC + bw, maxCol) - 1
        let minBR = bh * self.row
        let maxBR = min(minBR + bh, maxRow) - 1
        
        let c: Int
        if col < minBC {
            c = minBC
        } else if col > maxBC {
            c = maxBC
        } else {
            c = col
        }
        
        let r: Int
        if row < minBR {
            r = minBR
        } else if row > maxBR {
            r = maxBR
        } else {
            r = row
        }
        return (c, r)
    }
    
    func setBoardPosition(col: Int, row: Int,
                          isColLast: Bool, isRowLast: Bool,
                          puzzleW: Int, puzzleH: Int,
                          animated: Bool = true, completion: (()->())? = nil) {
        if self.col == col && self.row == row {
            return;
        }
        
        print("\(self.col),\(self.row)==>\(col),\(row)")
        
        if animating {
            return
        }
        
        guard let bw = board?.verticalSize.width,
            let bh = board?.verticalSize.height else {
            return
        }
        
        animating = true
        
        let isSingleCol = bw >= puzzleW
        let isSingleRow = bh >= puzzleH
        let isColFirst = col == 0
        let isRowFirst = row == 0
        let isCenteringX = isSingleCol || (!isColFirst && !isColLast)
        let isCenteringY = isSingleRow || (!isRowFirst && !isRowLast)
        let pw = originSize*(CGFloat(bw)+0.5)
        let ph = originSize*(CGFloat(bh)+0.5)
        
        let xOff: CGFloat
        if isSingleCol {
            xOff = (view.bounds.width-(originSize*(CGFloat(bw))))*0.5
        } else if isCenteringX {
            xOff = (view.bounds.width-pw)*0.5
        } else if isColFirst {
            xOff = view.bounds.width-pw
        } else {
            xOff = view.bounds.width-pw+originSize*0.5
        }
        
        let yOff: CGFloat
        if isSingleRow {
            yOff = (view.bounds.height-(originSize*(CGFloat(bh))))*0.5
        } else if isCenteringY {
            yOff = (view.bounds.height-ph)*0.5
        } else if isRowFirst {
            yOff = view.bounds.height-ph
        } else {
            yOff = view.bounds.height-ph//+originSize*0.5
        }
        
        let cp = CGPoint(x: -CGFloat(bw * col) * originSize + xOff,
                         y: -CGFloat(bh * row) * originSize + yOff)
        set(centerPoint: cp, row: row, col: col, animated: animated, completion: completion)
    }
    
    private func set(centerPoint cp: CGPoint, row: Int, col: Int, animated: Bool, completion: (()->())? = nil) {
        self.col = col
        self.row = row
        
        bgimg.alpha = 0.15
        
        if animated {
            let mpcx = view.bounds.width * 0.5
            let mpcy = view.bounds.height * 0.5
            
            let mpc = pieceContainer.convert(CGPoint(x: mpcx, y: mpcy), from: view)
            let mpci = bgimg.convert(CGPoint(x: mpcx, y: mpcy), from: view)
            
            pieceContainer.mAnchorXY = mpc
            bgimg.mAnchorXY = mpci
            
            //first phase
            UIView.animate(withDuration: 0.6, delay: 0.05, options: [.curveEaseInOut], animations: {
                //anims 1
                self.pieceContainer.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.bgimg.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                
            }, completion: { (finished) in
                if finished {
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
                        if finished {
                            self.animating = false
                            completion?()
                        }
                    })
                }
            })
        } else {
            self.pieceContainer.center = cp
            self.bgimg.center = cp
            self.animating = false
        }
        
        self.border.strokeColor = UIColor(white: 1.0, alpha: 0.25).cgColor
    }
    
    func setFinishedState(withCompletion: (()->())?) {
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
            if finished {
                withCompletion?()
            }
        }
    }
}
