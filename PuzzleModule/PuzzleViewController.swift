//  PuzzleViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

@objc public protocol PuzzleOutput: class
{
    func didCompletePuzzle()
}

@objc protocol PuzzleInput: class
{
    func configure(withPaths: [[CGPath]], frames: [[CGRect]], image: UIImage, difficulty: EAPuzzleDifficulty, originSize: CGFloat, w: Int, h: Int, puzzleState: PuzzleState?, shuffle: Bool, boardBGColor: UIColor?, paletteBGColor: UIColor?)
    
    func storePuzzleState() -> PuzzleState
    
    func setBoardImageVisible(_ val: Bool)
    
    func setBGColors(_ board: UIColor?, _ palette: UIColor?)
    
    func deinitPuzzle()
}

public class PuzzleViewController: UIViewController, PuzzleInput
{
    
    public func deinitPuzzle()
    {
        self.view.gestureRecognizers?.forEach({ (gr) in
            self.view.removeGestureRecognizer(gr)
        })
        
        self.timer?.invalidate()
        self.timer = nil
        
        self.pcs.forEach { (p) in
            p.unsub()
        }
        self.gr.forEach { (pg) in
            pg.unsub()
        }
        self.pcs.removeAll()
        self.gr.removeAll()
        
        self.boardController.unsub()
        self.paletteController.unsub()
        
        if self.lastDataSource != nil {
            self.lastDataSource.unsub()
        }
        
        if self.lastImage != nil {
            self.lastImage = nil
        }
        
        self.lastPaths.removeAll()
    }
    
    deinit {
        //print("deinit")
    }
    
    public func setBoardImageVisible(_ val: Bool) {
        self.boardController.setBoardImageVisible(val)
    }
    
    public func storePuzzleState() -> PuzzleState {
        return PuzzleState(from: self)
    }
    
    func setBGColors(_ board: UIColor?, _ palette: UIColor?)
    {
        if let board = board
        {
            self.boardController.setBoardBGColor(board)
        }
        
        if let palette = palette
        {
            self.paletteController.setPaletteBGColor(palette)
        }
    }
    
    weak var output: PuzzleOutput?
    var pcs: [Piece] = []
    var gr: [PieceGroup] = []
    var blockCounter: Int = 0
    
    var sectionTransition: Bool = false
    
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
    
    var boardSize: CGSize {
        let ins = PuzzleModule.insets
        let s = UIScreen.main.bounds
        return CGSize(width: s.width-ins.left-ins.right,
                      height: s.height-paletteHeight-ins.top-ins.bottom)
    }
    
    lazy var boardController: BoardViewController = {
        
        let board = BoardViewController()
        
        return board
    }()
    
    override public func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        self.addChild(self.boardController)
        self.view.addSubview(self.boardController.view)
        
        self.addChild(self.paletteController)
        self.view.addSubview(self.paletteController.view)
        
        self.boardController.view.addTopConstraint(toView: self.view, attribute: .top, relation: .equal, constant: 0)
        self.boardController.view.addLeftConstraint(toView: self.view)
        self.boardController.view.addRightConstraint(toView: self.view)
        self.boardController.view.addBottomConstraint(toView: self.paletteController.view, attribute: .top, relation: .equal, constant: 0.0)
        
        self.paletteController.view.addLeftConstraint(toView: self.view)
        self.paletteController.view.addRightConstraint(toView: self.view)
        self.paletteController.view.addBottomConstraint(toView: self.view)
        self.paletteController.view.addHeightConstraint(toView: nil, relation: .equal, constant: self.paletteHeight)
    }
    
    @objc func checkCompletion() {
        DispatchQueue.main.async {
            if self.gr.count == 1 {
                if self.paletteController.data.count == 0 {
                    if self.pcs.count == self.gr[0].pieces.count {
                        let items = self.lastDataSource.getPieceItems(forBoardColumn: self.boardController.col, boardRow: self.boardController.row)
                        if self.boardController.isAllItemsOnBoard(items) {
                            if self.sectionTransition {
                                return;
                            }
                            self.sectionTransition = true
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
    
    var panPiece: Piece?
    @objc func didPanTouchView(_ pan: UIPanGestureRecognizer) {
        if let p = self.panPiece {
            p.pan(pan)
            if pan.state == .ended
                || pan.state == .cancelled
                || pan.state == .failed {
                self.panPiece = nil
            }
        } else {
            if pan.state == .began {
                if let p = self.boardController.panTouchingPiece(pan) {
                    p.pan(pan)
                    self.panPiece = p
                } else {
                    self.paletteController.didPanTouchView(pan)
                }
            } else {
                self.paletteController.didPanTouchView(pan)
            }
        }
    }
    
    var timer: Timer?
    var lastImage: UIImage!
    var lastSize: CGFloat = 0.0
    var lastDifficulty: EAPuzzleDifficulty!
    var lastDataSource: PuzzleDataSource!
    var lastPaths: [[CGPath]] = []
    var lastFrames: [[CGRect]] = []
    var lastShuffled: Bool = true
    var lastBoardBG: UIColor?
    var lastPaletteBG: UIColor?
    var lastW = 0
    var lastH = 0
    
    func configure(withPaths: [[CGPath]], frames: [[CGRect]], image: UIImage, difficulty: EAPuzzleDifficulty, originSize: CGFloat, w: Int, h: Int, puzzleState: PuzzleState?, shuffle: Bool, boardBGColor: UIColor?, paletteBGColor: UIColor?)
    {
        self.lastH = h
        self.lastW = w
        self.lastShuffled = shuffle
        self.lastPaths = withPaths
        self.lastFrames = frames
        self.lastSize = originSize
        self.lastImage = image
        self.lastDifficulty = difficulty
        self.lastPaletteBG = paletteBGColor
        self.lastBoardBG = boardBGColor
        
        if let boardBG = boardBGColor
        {
            self.boardController.setBoardBGColor(boardBG)
        }
        
        if let paletteBG = paletteBGColor
        {
            self.paletteController.setPaletteBGColor(paletteBG)
        }
        
        
        let vertical = EAPuzzleBoardSize(withWidth: w,
                                         height: h)
        let horizontal = EAPuzzleBoardSize(withWidth: vertical.height,
                                           height: vertical.width)
        
        let boardSize = EAPuzzleBoard(withHorizontalSize: horizontal,
                                      verticalSize: vertical)
        
        let pieces: CGFloat = CGFloat(boardSize.verticalSize.width)
        let vPieces: CGFloat = CGFloat(boardSize.verticalSize.height)
        
        let bs = self.boardSize
        
        let www = bs.width/(pieces+0.5)
        let hhh = bs.height/(vPieces+0.5)
        
        let scale: CGFloat
        if www <= hhh {
            scale = www/originSize
        } else {
            scale = hhh/originSize
        }
        
        let s = (originSize*scale) * CGFloat(difficulty.width) / image.size.width
        
        let img = image.resizedImage(scale: s)
        
        let dataSource = PuzzleDataSource(withPiecePaths: withPaths, frames: frames, difficulty: difficulty, scale: scale, originSize: originSize, boardSize: boardSize, puzzleImage: self.imgWithBorder(img))
        self.lastDataSource = dataSource
        
        self.boardController.setBoardSize(boardSize, originSize: originSize*scale)
        
        self.boardController.setBackgroundImage(img, withMaxCols: difficulty.width, maxRows: difficulty.height)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: {
            
            if let state = puzzleState {
                // load puzzle
                self.loadState(state)
            } else {
                // new puzzle
                self.setBoardPosition(0, row: 0)
            }
            self.remakeTimer()
        })
    }
    
    func imgWithBorder(_ image: UIImage) -> UIImage
    {
        let s = image.size
        UIGraphicsBeginImageContext(s)
        let rect = CGRect(origin: CGPoint.zero, size: s)
        image.draw(in: rect)
        let c = UIGraphicsGetCurrentContext()
        c?.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        c?.stroke(rect, width: 15.0)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let img = img {
            return img
        }
        return image
    }
    
    func loadState(_ state: PuzzleState)
    {
        let col = state.boardPositionC
        let row = state.boardPositionR
        
        let sorted = state.palettePieces.sorted { $0.paletteIndex < $1.paletteIndex }
        let paletteItems = self.lastDataSource.getPieceItemsByPieceStates(sorted)
        self.paletteController.setDataItems(paletteItems)
        
        for stateItem in state.boardPieces
        {
            if let item = self.lastDataSource.getPieceItemById(stateItem.uid)
            {
                let p = self.lastDataSource.getPiece(forItem: item)
                self.boardController.addPiece(p)
                self.pcs.append(p)
                p.setPosition(col: stateItem.curX, row: stateItem.curY, rotation: stateItem.rotation)
                p.output = self
            }
        }
        
        let cl = (self.lastDataSource.boardSize.verticalSize.width * (col+1)) >= self.lastDataSource.difficulty.width
        let rw = (self.lastDataSource.boardSize.verticalSize.height * (row+1)) >= self.lastDataSource.difficulty.height
        
        self.boardController.setBoardPosition(col: col, row: row,
                                              isColLast: cl, isRowLast: rw,
                                              puzzleW: self.lastDataSource.difficulty.width,
                                              puzzleH: self.lastDataSource.difficulty.height,
                                              animated: false)
        
        self.pcs.forEach({ (p) in
            // performance ??
            self.didSnap(piece: p)
        })
        
//        DispatchQueue.global().async {
//            self.preloadPieceItems()
//        }
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
        
        if self.lastShuffled
        {
            self.paletteController.setDataItems(items.shuffled())
        } else
        {
            self.paletteController.setDataItems(items)//no shuffle
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
            
            let dur = (col+row == 0) ? 0.0 : 1.25
            
            let cl = (self.lastDataSource.boardSize.verticalSize.width * (col+1)) >= self.lastDataSource.difficulty.width
            let rw = (self.lastDataSource.boardSize.verticalSize.height * (row+1)) >= self.lastDataSource.difficulty.height
            
            self.boardController.setBoardPosition(col: col, row: row,
                                                  isColLast: cl, isRowLast: rw,
                                                  puzzleW: self.lastDataSource.difficulty.width,
                                                  puzzleH: self.lastDataSource.difficulty.height, animated: dur>0, completion: { () in
                                                  self.sectionTransition = false
            })
        })
        /*
        if col == 0 && row == 0
        {
            
            DispatchQueue.global().async {
                print("preloadPieceItems")
                self.preloadPieceItems()
            }
 
        }
         */
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
    
    func didCompleteSection()
    {
        
        if let nxt = self.getNextUncompletedRowCol(fromCol: self.boardController.col,
                                                   fromRow: self.boardController.row)
        {
            self.setBoardPosition(nxt.0, row: nxt.1)
        } else
        {
            // Puzzle comleted
            
            self.view.gestureRecognizers?.forEach({ (gr) in
                self.view.removeGestureRecognizer(gr)
            })
            self.timer?.invalidate()
            self.timer = nil
            
            
            self.boardController.setFinishedState(withCompletion: { 
                
                self.output?.didCompletePuzzle()
            })
            
        }
    }
    
    func getNextUncompletedRowCol(fromCol: Int, fromRow: Int) -> (Int, Int)?
    {
        let col = fromCol + ((fromRow%2==0) ? 1 : -1)
        let row = fromRow
        
        if self.hasUncompletedPieces(atCol: col, row: row)
        {
            return (col, row)
        } else if self.hasUncompletedPieces(atCol: fromCol, row: row+1)
        {
            return (fromCol, row+1)
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
        self.configure(withPaths: self.lastPaths, frames: self.lastFrames, image: self.lastImage, difficulty: self.lastDifficulty, originSize: self.lastSize, w: self.lastW, h: self.lastH, puzzleState: nil, shuffle: self.lastShuffled, boardBGColor: self.lastBoardBG, paletteBGColor: self.lastPaletteBG)
    }
}

extension PuzzleViewController: PaletteOutput
{
    func getProxy(fromItem: PieceItem) -> UIImageView
    {
        return self.lastDataSource.getPieceItemImageViewProxy(pieceItem: fromItem)
    }
    
    func getProxyAsync(fromItem: PieceItem, completion: @escaping (UIImageView) -> ())
    {
        
        DispatchQueue.main.async {
            let proxy = self.lastDataSource.getPieceItemImageViewProxy(pieceItem: fromItem)
            
            completion(proxy)
        }
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
            self.boardController.view.window?.isUserInteractionEnabled = false
            //if piece on board -> insert piece on board view
            self.paletteController.didGrabItem(pieceItem)
            self.boardController.addPiece(p)
            if !self.pcs.contains(p)
            {
                self.pcs.append(p)
                p.output = self
            }
            UIView.animate(withDuration: 0.12,
                           animations: {
                p.snapToGrid(false)
                
            }, completion: { (finished) in
                if finished
                {
                    DispatchQueue.main.async {
                        p.dispatchSnap()
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.08, execute: {
                            
                            self.boardController.view.window?.isUserInteractionEnabled = true
                        })
                    }
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
            self.view.window?.isUserInteractionEnabled = false
            
            //if piece on board -> insert piece on board view
            self.boardController.addPiece(p)
            if !self.pcs.contains(p)
            {
                self.pcs.append(p)
                p.output = self
            }
            self.paletteController.didGrabItem(p.item)
            
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
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.08, execute: {
                
                self.view.window?.isUserInteractionEnabled = true
            })
            
            
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
            self.boardController.view.bringSubviewToFront(ps)
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
                        let items = self.lastDataSource.getPieceItems(forBoardColumn: self.boardController.col, boardRow: self.boardController.row)
                        if self.boardController.isAllItemsOnBoard(items)
                        {
                            if sectionTransition
                            {
                                return;
                            }
                            sectionTransition = true
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.2,
                                                          execute: {
                                                            
                                                            print("$puzzle didCompleteSection didSnap");
                                                            self.didCompleteSection()
                            })
                        }
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
            let checkGridExt = [(1,-3),    (2,-3),  (3,-2),  (3,-1),
                                (3,1),   (3,2), (2,3),  (1,3),
                                (-1,3),    (-2,3), (-3,2),  (-3,1),
                                (-3,-1),    (-3,-2), (-2,-3), (-1,-3),
                                (0,-4),    (4,0), (0,4),  (-4,0),
                                (3,-3),    (3,3),(-3,3), (-3,-3),
                                (1,-4),(2,-4),(3,-4),(4,-4),(4,-3),(4,-2),(4,-1),(4,1),(4,2),(4,3),(4,4),(3,4),(2,4),(1,4),(-1,4),(-2,4),(-3,4),(-4,4),(-4,3),(-4,2),(-4,1),(-4,-1),(-4,-2),(-4,-3),(-4,-4),(-3,-4),(-2,-4),(-1,-4),
                                (0,-5),(5,0),(0,-5),(-5,0),(5,-5),(5,5),(-5,5),(-5,-5),
                                (0,-6),(6,0),(0,-6),(-6,0),(6,-6),(6,6),(-6,6),(-6,-6),
                                (0,-7),(7,0),(0,-7),(-7,0),(7,-7),(7,7),(-7,7),(-7,-7),
                                (0,-8),(8,0),(0,-8),(-8,0),(8,-8),(8,8),(-8,8),(-8,-8)]
            for check in checkGridExt
            {
                if self.boardController.isColRowInside(col: ngx+check.0, row: ngy+check.1)
                {
                    return piece.item.translationToGridCell(col: ngx+check.0, row: ngy+check.1)
                }
            }
        }
        return piece.item.translationToGridCell(col: 0, row: 0)
    }
}

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            self.swapAt(firstUnshuffled, i)
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
