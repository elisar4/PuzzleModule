//  PuzzleViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

@objc public protocol PuzzleOutput: class
{
    func didCompletePuzzle()
}

protocol PuzzleInput: class
{
    func configure(withPaths: [[CGPath]], image: UIImage, difficulty: EAPuzzleDifficulty, originSize: CGFloat)
}

public class PuzzleViewController: UIViewController, BoardOutput, PuzzleInput
{
    weak var output: PuzzleOutput?
    var pcs: [Piece] = []
    var gr: [PieceGroup] = []
    
    let paletteHeight: CGFloat = 94.0
    
    lazy var paletteController: PaletteViewController = {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        layout.itemSize = CGSize(width: self.paletteHeight-10,
                                 height: self.paletteHeight-10)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        
        let palette = PaletteViewController(collectionViewLayout: layout)
        palette.output = self
        
        return palette
    }()
    
    lazy var boardController: BoardViewController = {
        
        let board = BoardViewController()
        board.output = self
        
        return board
    }()
    
    override public func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        self.addChildViewController(self.boardController)
        self.view.addSubview(self.boardController.view)
        
        self.addChildViewController(self.paletteController)
        self.view.addSubview(self.paletteController.view)
        
        self.boardController.view.addTopConstraint(toView: self.view, attribute: .top, relation: .equal, constant: 0)
        self.boardController.view.addLeftConstraint(toView: self.view)
        self.boardController.view.addRightConstraint(toView: self.view)
        self.boardController.view.addBottomConstraint(toView: self.paletteController.view, attribute: .top, relation: .equal, constant: 0.0)
        
        self.paletteController.view.addLeftConstraint(toView: self.view)
        self.paletteController.view.addRightConstraint(toView: self.view)
        self.paletteController.view.addBottomConstraint(toView: self.view)
        self.paletteController.view.addHeightConstraint(toView: nil, relation: .equal, constant: self.paletteHeight)
        
        print("puzzle view did load")
    }
    
    func checkCompletion()
    {
        if self.gr.count == 1
        {
            if self.paletteController.data.count == 0
            {
                if self.pcs.count == self.gr[0].pieces.count
                {
                    self.didCompleteSection()
                }
            }
        }
    }
    
    func didPanTouchView(_ pan: UIPanGestureRecognizer)
    {
        self.paletteController.didPanTouchView(pan)
    }
    
    var timer: Timer?
    var lastImage: UIImage!
    var lastSize: CGFloat = 0.0
    var lastDifficulty: EAPuzzleDifficulty!
    var lastDataSource: PuzzleDataSource!
    var lastPaths: [[CGPath]] = []
    
    func configure(withPaths: [[CGPath]], image: UIImage, difficulty: EAPuzzleDifficulty, originSize: CGFloat)
    {
        self.lastPaths = withPaths
        self.lastSize = originSize
        self.lastImage = image
        self.lastDifficulty = difficulty
        
        let coeff: CGFloat = (UIDevice.current.userInterfaceIdiom == .phone) ? -0.05 : +0.05
        let boardSize = self.preferedBoardSize(withOrigin: originSize,
                                               difficulty: difficulty,
                                               pieceCoefficient: coeff)
        
        let pieces: CGFloat = CGFloat(boardSize.verticalSize.width)
        
        let screenSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let scale = screenSize / (pieces+0.5) / originSize
        
        let size = originSize * CGFloat(max(difficulty.height, difficulty.width)) * scale
        
        let img = image.resizedImage(toSize: CGSize(width: size, height: size))
        
        let dataSource = PuzzleDataSource(withPiecePaths: withPaths, difficulty: difficulty, scale: scale, originSize: originSize, boardSize: boardSize, puzzleImage: img)
        self.lastDataSource = dataSource
        
        self.boardController.setBoardSize(boardSize, originSize: originSize * scale)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
            self.setBoardPosition(0, row: 0)
            //self.addAllPiecesToBoardRandomly(fromDataSource: dataSource)
            
            self.remakeTimer()
        })
    }
    
    func remakeTimer()
    {
        self.view.gestureRecognizers?.forEach({ (gr) in
            self.view.removeGestureRecognizer(gr)
        })
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PuzzleViewController.didPanTouchView(_:)))
        pan.cancelsTouchesInView = false
        self.view.addGestureRecognizer(pan)
        
        self.timer?.invalidate()
        self.timer = nil
        self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(PuzzleViewController.checkCompletion), userInfo: nil, repeats: true)
    }
    
    func addAllPiecesToBoardRandomly(fromDataSource dataSource: PuzzleDataSource)
    {
        for item in dataSource.pcsItms
        {
            let p = dataSource.getPiece(forItem: item)
            self.boardController.addPiece(p)
            self.pcs.append(p)
            p.randomPosition(maxCol: dataSource.difficulty.width,
                             maxRow: dataSource.difficulty.height)
            p.output = self
        }
    }
    
    func setBoardPosition(_ col: Int, row: Int)
    {
        
        let items = self.lastDataSource.getPieceItems(forBoardColumn: col, boardRow: row)
        self.paletteController.setDataItems(items)//items.shuffled())
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
            
            UIView.animate(withDuration: 1.25, delay: 0.0, options: [.preferredFramesPerSecond60, .layoutSubviews, .curveEaseInOut], animations: {
                
                
                let cl = (self.lastDataSource.boardSize.verticalSize.width * (col+1)) >= self.lastDataSource.difficulty.width
                let rw = (self.lastDataSource.boardSize.verticalSize.height * (row+1)) >= self.lastDataSource.difficulty.height
                
                self.boardController.setBoardPosition(col: col, row: row,
                                                      isColLast: cl, isRowLast: rw,
                                                      puzzleW: self.lastDataSource.difficulty.width,
                                                      puzzleH: self.lastDataSource.difficulty.height)
                
            }, completion: nil)
        })
        
        if col == 0 && row == 0
        {
            DispatchQueue.global().async {
                print("preloadPieceItems")
                self.preloadPieceItems()
            }
        }
    }
    
    func preloadPieceItems()
    {
        var col = 0
        var row = 0
        while let nxt = self.getNextUncompletedRowCol(fromCol: col,
                                                      fromRow: row)
        {
            col = nxt.0
            row = nxt.1
            let items = self.lastDataSource.getPieceItems(forBoardColumn: col,
                                                          boardRow: row)
            //print("preloaded items at: ", col, row)
            
            for item in items
            {
                _ = self.lastDataSource.getPiece(forItem: item)
                //print("preloaded piece: ", item.uid)
            }
        }
    }
    
    func hasUncompletedPieces(atCol: Int, row: Int) -> Bool
    {
        let items = self.lastDataSource.getPieceItems(forBoardColumn: atCol, boardRow: row)
        return self.hasUncompletedPieces(items)
    }
    
    func hasUncompletedPieces(_ pieceItems: [PieceItem]) -> Bool
    {
        if pieceItems.count > 0
        {
            let pss = pieceItems.filter({ (pi) -> Bool in
                return pi.dx != 0
                    || pi.dy != 0
                    || pi.rotation != .origin
                    || !pi.locked
            })
            //maybe need to check Piece's from pss items
            
//            for pi in pss
//            {
//                let p = self.lastDataSource.getPiece(forItem: pi)
//                if p.isHidden
//                {
//                    return true
//                }
//                if p.superview == nil
//                {
//                    return true
//                }
//            }
            
            return pss.count > 0
        }
        return false
    }
    
    func preferedBoardSize(withOrigin: CGFloat, difficulty: EAPuzzleDifficulty, pieceCoefficient: CGFloat) -> EAPuzzleBoard
    {
        let piecesMinSize: CGFloat = 48.0
        let piecesMaxSize: CGFloat = 128.0
        
        let screenSizeMIN = min(self.boardController.view.frame.size.width,
                                self.boardController.view.frame.size.height)
        let screenSizeMAX = max(self.boardController.view.frame.size.width,
                                self.boardController.view.frame.size.height)
        
        let mxw = Int(screenSizeMIN / piecesMinSize)
        let mnw = Int(screenSizeMIN / piecesMaxSize)
        
        var bestOption = 0
        var bestOptionValue: CGFloat = 0.0
        for i in mnw...mxw
        {
            let coeff = CGFloat(mxw - i) * pieceCoefficient
            let z = CGFloat(difficulty.width) / CGFloat(i)
            let c = z / CGFloat(Int(ceil(z))) + coeff
            if c > bestOptionValue
            {
                bestOptionValue = c
                bestOption = i
            }
        }
        
        let pieceSize = screenSizeMIN / CGFloat(bestOption)
        
        let vertical = EAPuzzleBoardSize(withWidth: Int(screenSizeMIN/pieceSize),
                                         height: Int(screenSizeMAX/pieceSize))
        let horizontal = EAPuzzleBoardSize(withWidth: vertical.height,
                                           height: vertical.width)
        
        return EAPuzzleBoard(withHorizontalSize: horizontal,
                             verticalSize: vertical)
    }
    
    func didCompleteSection()
    {
        print("didCompleteSection")
        
        if let nxt = self.getNextUncompletedRowCol(fromCol: self.boardController.col,
                                                   fromRow: self.boardController.row)
        {
            self.setBoardPosition(nxt.0, row: nxt.1)
        } else
        {
            // Puzzle comleted
            self.output?.didCompletePuzzle()
            self.view.gestureRecognizers?.forEach({ (gr) in
                self.view.removeGestureRecognizer(gr)
            })
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func getNextUncompletedRowCol(fromCol: Int, fromRow: Int) -> (Int, Int)?
    {
        var col = fromCol
        let row = fromRow
        col += (row%2==0) ? 1 : -1
        
        if self.hasUncompletedPieces(atCol: col, row: row)
        {
            return (col, row)
        } else if self.hasUncompletedPieces(atCol: fromCol, row: row+1)
        {
            return (col, row+1)
        }
        
        return nil
    }
    
    func clearBoard()
    {
        for p in self.pcs
        {
            p.removeFromSuperview()
        }
        self.pcs.removeAll()
        self.gr.removeAll()
    }
    
    func resetPuzzleRequest()
    {
        self.clearBoard()
        self.configure(withPaths: self.lastPaths, image: self.lastImage, difficulty: self.lastDifficulty, originSize: self.lastSize)
    }
}

extension PuzzleViewController: PaletteOutput
{
    func getProxy(fromItem: PieceItem) -> UIImageView
    {
        return self.lastDataSource.getPieceItemImageViewProxy(pieceItem: fromItem)
    }
    
    func didPick(pieceItem: PieceItem, atPoint: CGPoint)
    {
        let p = self.lastDataSource.getPiece(forItem: pieceItem)
        if p.superview == nil
        {
            self.view.window?.addSubview(p)
        }
        p.isUserInteractionEnabled = false
        p.isHidden = false
        
        if let pt = self.view.window?.convert(atPoint, from: self.paletteController.view)
        {
            p.mAnchor = CGPoint(x: 0.5, y: 0.5)
            p.rotation = pieceItem.rotation
            p.center = pt
        }
    }
    
    func didMove(pieceItem: PieceItem, by: CGPoint)
    {
        let p = self.lastDataSource.getPiece(forItem: pieceItem)
        p.center = CGPoint(x: p.center.x + by.x,
                           y: p.center.y + by.y)
        self.paletteController.hoverPiece(p)
    }
    
    func didDrop(pieceItem: PieceItem, atPoint: CGPoint)
    {
        let p = self.lastDataSource.getPiece(forItem: pieceItem)
        p.isUserInteractionEnabled = true
        
        if self.boardController.canPlacePieceOnBoard(p)
        {
            //if piece on board -> insert piece on board view
            self.paletteController.didGrabItem(pieceItem)
            self.boardController.addPiece(p)
            if !self.pcs.contains(p)
            {
                self.pcs.append(p)
                p.output = self
            }
            
            UIView.animate(withDuration: 0.15,
                           animations: {
                p.snapToGrid(false)
            }, completion: { (finished) in
                
                DispatchQueue.global().async {
                    p.dispatchSnap()
                }
            })
        } else
        {
            //else -> return to palette
            self.paletteController.didReturnToPalette(p)
        }
    }
}

extension PuzzleViewController: PieceOutput
{
    
    func didDropSinglePiece(_ piece: Piece) -> Bool
    {
        let p = piece
        p.isUserInteractionEnabled = true
        
        if self.boardController.canPlacePieceOnBoard(p)
        {
            //if piece on board -> insert piece on board view
            self.paletteController.didGrabItem(p.item)
            self.boardController.addPiece(p)
            if !self.pcs.contains(p)
            {
                self.pcs.append(p)
                p.output = self
            }
            
//            UIView.animate(withDuration: 0.15,
//                           animations: {
//                            p.snapToGrid(false)
//            }, completion: { (finished) in
//                
//                DispatchQueue.global().async {
//                    
//                    p.dispatchSnap()
//                }
//            })
            return false
        } else
        {
            //else -> return to palette
            print("did return")
            self.paletteController.didReturnToPalette(piece)
            return true
        }
    }
    
    func didMoveSinglePiece(_ piece: Piece)
    {
        self.paletteController.hoverPiece(piece)
    }
    
    func didPickSinglePiece(_ piece: Piece)
    {
        if let wnd = self.view.window,
            let pt = piece.superview?.convert(piece.center, to: wnd)
        {
            self.view.window?.addSubview(piece)
            piece.center = pt
        }
    }
    
    func processGroup(_ piece: Piece)
    {
        let maxDist = (self.lastDataSource.originSize * self.lastDataSource.scale) * 3
        var shouldRepeat = false
        for p in self.pcs
        {
            let dist = piece.center.distance(toPoint: p.center)
            if dist > maxDist
            {
                continue
            }
            if piece.canGroup(withPiece: p)
            {
                if let gr1 = piece.group
                {
                    if let gr2 = p.group
                    {
                        let removedGroup = gr1.combine(withGroup: gr2)
                        if let ind = self.gr.index(where: { $0.uid == removedGroup.uid })
                        {
                            self.gr.remove(at: ind)
                        }
                        shouldRepeat = true
                    } else
                    {
                        gr1.append(piece: p)
                        shouldRepeat = true
                    }
                } else if let gr2 = p.group
                {
                    gr2.append(piece: piece)
                    shouldRepeat = true
                } else
                {
                    self.gr.append(PieceGroup(withPieces: [piece, p]))
                    shouldRepeat = true
                }
            }
        }
        
        if shouldRepeat
        {
            self.processGroup(piece)
        }
    }
    
    func updateZIndexes()
    {
        for g in self.gr
        {
            g.updateZIndex()
        }
        
        let individualPieces = self.pcs.filter { $0.group == nil }
        for p in individualPieces
        {
            p.layer.zPosition = p.lastAction
        }
        
        let zSorted = self.pcs.sorted { $0.layer.zPosition < $1.layer.zPosition }
        for ps in zSorted
        {
            self.boardController.view.bringSubview(toFront: ps)
        }
    }
    
    func didSnap(piece: Piece)
    {
        self.processGroup(piece)
//        for p in self.pcs
//        {
//            self.processGroup(p)
//        }
        self.updateZIndexes()
        piece.group?.checkLocked()
        
        if self.gr.count == 1
        {
            if self.gr[0].isLocked
            {
                if self.paletteController.data.count == 0
                {
                    if self.pcs.count == self.gr[0].pieces.count
                    {
                        self.didCompleteSection()
                    }
                }
            }
        }
    }
    
    func didRotate(piece: Piece)
    {
        for p in self.pcs
        {
            self.processGroup(p)
        }
        self.updateZIndexes()
    }
    
    func correctedSnapPoint(forPiece piece: Piece) -> CGPoint
    {
        let oldCenter = piece.center
        let trans = piece.item.translationToNearestSnapPoint
        piece.center = CGPoint(x: piece.center.x + trans.x,
                               y: piece.center.y + trans.y)
        
        let ngx = piece.item.nearestGX
        let ngy = piece.item.nearestGY
        
        piece.center = oldCenter
        
        if self.boardController.isColRowInside(col: ngx, row: ngy)
        {
            return trans
        } else
        {
            let checkGrid = [(0,-1),    (1,0),  (0,1),  (-1,0),
                             (-1,-1),   (1,-1), (1,1),  (-1,1),
                             (-2,0),    (0,-2), (2,0),  (0,2),
                             (-1,2),    (-2,1), (-2,1), (-1,-2),
                             (1,-2),    (2,-1), (2,1),  (1,2),
                             (-2,2),    (-2,-2),(2,-2), (2,2),
                             (0,3),     (-3,0), (0,-3), (3,0)]
            for check in checkGrid
            {
                if self.boardController.isColRowInside(col: ngx+check.0, row: ngy+check.1)
                {
                    return piece.item.translationToGridCell(col: ngx+check.0, row: ngy+check.1)
                }
            }
        }
        return trans
    }
}

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
