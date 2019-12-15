//  SKBoardNode.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKPieceContainer: SKSpriteNode {
    
}

class SKBoardNode: SKSpriteNode {
    
    let container = SKPieceContainer(texture: nil, color: UIColor.yellow.withAlphaComponent(0.15), size: CGSize(width: 3800, height: 3800))
    
    var board: EAPuzzleBoard?
    var originSize: CGFloat = 0.0
    
    var base = SKNode()
    
    var bgNode = SKSpriteNode()
    
    var border = SKShapeNode()
    
    var col: Int = -1
    var row: Int = -1
    
    var maxCol: Int = 0
    var maxRow: Int = 0
    
    var animating: Bool = false
    
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat) {
        board = boardSize
        self.originSize = originSize
    }
    
    func setBackgroundImage(_ image: UIImage, withMaxCols: Int, maxRows: Int) {
        self.maxCol = withMaxCols
        self.maxRow = maxRows
        
        let mx = width
        let my = height
        
        bgNode.size = CGSize(width: mx, height: my)
        bgNode.texture = SKTexture(image: image)
        
        container.size = CGSize(width: mx, height: my)
        
        border.path = UIBezierPath(rect: CGRect(x: 4, y: 4, width: mx - 8, height: my - 8)).cgPath
        
        base.position = CGPoint(x: 0, y: -my + size.height)
    }
    
    var width: CGFloat {
        return CGFloat(maxCol) * originSize
    }
    
    var height: CGFloat {
        return CGFloat(maxRow) * originSize
    }
    
    func didUpdateSize() {
        base.position = CGPoint(x: 0, y: -height + size.height)
        
    }
    
    func addPiece(_ piece: SKPiece) {
        container.addChild(piece)
    }
    
    func removePiece(_ piece: SKPiece) {
        piece.removeFromParent()
    }
    
    func piece(at: CGPoint) -> SKPiece? {
        let ns = container.nodes(at: at)
        var nearest: SKPiece?
        var nearestDistance: CGFloat = 10_000
        for n in ns {
            if let p = n as? SKPiece {
                let dist = p.position.distance(toPoint: at)
                if dist < nearestDistance {
                    nearestDistance = dist
                    nearest = p
                }
            }
        }
        return nearest
    }
    
    
    func isColRowInside(col: Int, row: Int) -> Bool {
        let bw = board?.verticalSize.width ?? 0
        let bh = board?.verticalSize.height ?? 0
        
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
    
//    func corrected(_ piece: Piece) -> (Int, Int) {
//        return snapPoint(piece)
//    }
    
    func corrected(col: Int, row: Int) -> (Int, Int) {
        if isColRowInside(col: col, row: row) {
            return (col, row)
        }
        
        let bw = board?.verticalSize.width ?? 0
        let bh = board?.verticalSize.height ?? 0
        
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
                          animated: Bool = true,
                          completion: (() -> Void)? = nil) {
        if self.col == col && self.row == row {
            return
        }
        
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
        let pw = originSize * (CGFloat(bw) + 0.5)
        let ph = originSize * (CGFloat(bh) + 0.5)
        
        let s = size
        
        let xOff: CGFloat
        if isSingleCol {
            xOff = (s.width - (originSize * (CGFloat(bw)))) * 0.5
        } else if isCenteringX {
            let rowOdd = CGFloat(row).remainder(dividingBy: 2.0) == 0.0
            let os = rowOdd ? originSize * 0.35 : originSize * 0.1
            xOff = (s.width - pw) * 0.5 + os
        } else if isColFirst {
            xOff = s.width - pw
        } else {
            xOff = s.width - pw + originSize * 0.5
        }
        
        let yOff: CGFloat
        if isSingleRow {
            yOff = (s.height - (originSize * (CGFloat(bh)))) * 0.5
        } else if isCenteringY {
            yOff = (s.height - ph) * 0.5 + originSize * 0.35
        } else if isRowFirst {
            yOff = s.height - ph
        } else {
            yOff = s.height - ph//+originSize*0.5
        }
        
        let cp = CGPoint(x: -CGFloat(bw * col) * originSize + xOff,
                         y: -CGFloat(bh * row) * originSize + yOff)
        set(centerPoint: cp, row: row, col: col, animated: animated, completion: completion)
    }
    
    private func set(centerPoint cp: CGPoint, row: Int, col: Int, animated: Bool, completion: (() -> Void)? = nil) {
        self.col = col
        self.row = row
        
        let s = size
        let cs = container.size
        
        if animated {
            let mpcx = s.width * 0.5
            let mpcy = s.height * 0.5
            
            let mpc = base.convert(CGPoint(x: mpcx, y: mpcy), from: self)
//            let mpci = bgimg.convert(CGPoint(x: mpcx, y: mpcy), from: view)
            
//            pieceContainer.mAnchorXY = mpc
//            bgimg.mAnchorXY = mpci
            
            //first phase
//            UIView.animate(withDuration: 0.6, delay: 0.05, options: [.curveEaseInOut], animations: {
//                //anims 1
//                self.pieceContainer.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//                self.bgimg.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//
//            }, completion: { (finished) in
//                if finished {
//                    self.pieceContainer.mAnchor = CGPoint.zero
//                    self.bgimg.mAnchor = CGPoint.zero
//
//                    //second phase
//                    UIView.animate(withDuration: 0.9, delay: 0.11, options: [.curveEaseInOut], animations: {
//                        //anims2
                        
                        //self.pieceContainer.transform = CGAffineTransform.identity
                        //self.bgimg.transform = CGAffineTransform.identity
                        //self.pieceContainer.center = cp
                        //self.bgimg.center = cp
            
            base.position = CGPoint(x: cp.x, y: s.height - cs.height - cp.y)
            self.animating = false
            completion?()
//
//                    }, completion: { (finished) in
//                        if finished {
//                            self.animating = false
//                            completion?()
//                        }
//                    })
//                }
//            })
        } else {
//            pieceContainer.center = cp
//            bgimg.center = cp
            base.position = CGPoint(x: cp.x, y: s.height - cs.height - cp.y)
            animating = false
            completion?()
        }
        
//        border.strokeColor = UIColor(white: 1.0, alpha: 0.25).cgColor
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        border.strokeColor = UIColor(white: 1.0, alpha: 0.4)
        border.fillColor = UIColor.clear
        border.lineWidth = 7.5
        border.zPosition = 500
        border.lineJoin = .miter
        
        bgNode.anchorPoint = CGPoint(x: 0, y: 0)
        bgNode.alpha = 0.15
        
        //backgroundColor = UIColor(white: 80.0/255.0, alpha: 1.0)
        addChild(base)
        base.position = CGPoint(x: 0, y: size.height)
        
        base.addChild(bgNode)
        
        anchorPoint = .zero
        
        container.anchorPoint = CGPoint(x: 0, y: 0)
        base.addChild(container)
        container.position = .zero
        
        base.addChild(border)
        
        bgNode.isUserInteractionEnabled = false
        border.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
