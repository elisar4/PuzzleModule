//  PuzzleViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit
import SpriteKit

@objc public protocol PuzzleOutput: class {
    func didCompletePuzzle()
    func didUpdate(progress: CGFloat)
    func pickPiece()
    func dropPiece()
    func groupPiece()
    func returnToPalette()
}

public class PuzzleViewController: UIViewController {
    
    weak var output: PuzzleOutput?
    var pcs: [SKPiece] = []
    var gr: [PieceGroup] = []
    var blockCounter: Int = 0
    
    var sectionTransition: Bool = false
    
    let paletteHeight: CGFloat = 94.0
    
    lazy var paletteController: PaletteViewController = {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        layout.itemSize = CGSize(width: self.paletteHeight - 10,
                                 height: self.paletteHeight - 10)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        
        let palette = PaletteViewController(collectionViewLayout: layout)
        palette.output = self
        
        return palette
    }()
    
    var boardSize: CGSize {
        let ins = PuzzleModule.insets
        let s = UIScreen.main.bounds
        return CGSize(width: s.width - ins.left - ins.right,
                      height: s.height - paletteHeight - ins.top - ins.bottom)
    }
    
    lazy var boardController: BoardViewController = {
        return BoardViewController()
    }()
    
    var inPlaceCount: Int {
        return pcs.filter({ (p) -> Bool in
            return p.item.dx == 0 && p.item.dy == 0
        }).count
    }
    
    var onBoardCount: Int {
        return pcs.count
    }
    
    var allCount: Int {
        return dataSource.pcsItms.count
    }
    
    public var currentProgress: CGFloat {
        let inPlace = inPlaceCount
        let all = allCount
        let onBoard = onBoardCount
        
        let b = CGFloat(onBoard) / CGFloat(all) * 0.15
        let p = CGFloat(inPlace) / CGFloat(all) * 0.85
        
        if p + b > 1.0 {
            return 1.0
        }
        return p + b
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        loadSKModule()
    }
    
    lazy var scene: SKMainScene = {
        return SKMainScene(size: self.view.bounds.size)
    } ()
    
    private func loadSKModule() {
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(skView)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        skView.presentScene(scene)
    }
    
    private func loadUIKitModule() {
        addChild(boardController)
        view.addSubview(boardController.view)
        
        addChild(paletteController)
        view.addSubview(paletteController.view)
        
        boardController.view.addTopConstraint(toView: view, attribute: .top, relation: .equal, constant: 0)
        boardController.view.addLeftConstraint(toView: view)
        boardController.view.addRightConstraint(toView: view)
        boardController.view.addBottomConstraint(toView: paletteController.view, attribute: .top, relation: .equal, constant: 0.0)
        
        paletteController.view.addLeftConstraint(toView: view)
        paletteController.view.addRightConstraint(toView: view)
        paletteController.view.addBottomConstraint(toView: view)
        paletteController.view.addHeightConstraint(toView: nil, relation: .equal, constant: paletteHeight)
    }
    
    @objc func checkCompletion() {
        DispatchQueue.main.async {
            self._checkCompletion()
        }
    }
    
    private func _checkCompletion() {
        if gr.count == 1 {
            if paletteController.data.count == 0 {
                if pcs.count == gr[0].pieces.count {
                    let items = dataSource.getPieceItems(forBoardColumn: boardController.col,
                                                             boardRow: boardController.row)
                    if boardController.isAllItemsOnBoard(items) {
                        if sectionTransition {
                            return
                        }
                        sectionTransition = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                            self.didCompleteSection()
                        })
                    }
                }
            }
        }
    }
    
    var panPiece: Piece?
    @objc func didPanTouchView(_ pan: UIPanGestureRecognizer) {
        if let p = panPiece {
            p.pan(pan)
            if pan.state == .ended
                || pan.state == .cancelled
                || pan.state == .failed {
                panPiece = nil
            }
        } else {
            if pan.state == .began {
                if let p = boardController.panTouchingPiece(pan) {
                    p.pan(pan)
                    panPiece = p
                } else {
                    paletteController.didPanTouchView(pan)
                }
            } else {
                paletteController.didPanTouchView(pan)
            }
        }
    }
    
    var timer: Timer?
    var lastImage: UIImage!
    var lastSize: CGFloat = 0.0
    var lastDifficulty: EAPuzzleDifficulty!
    var dataSource: PuzzleDataSource!
    var lastPaths: [[CGPath]] = []
    var lastFrames: [[CGRect]] = []
    var lastShuffled: Bool = true
    var lastBoardBG: UIColor?
    var lastPaletteBG: UIColor?
    var lastW = 0
    var lastH = 0
    
    func loadState(_ state: PuzzleState) {
        let col = state.boardPositionC
        let row = state.boardPositionR
        
        let sorted = state.palettePieces.sorted { $0.paletteIndex < $1.paletteIndex }
        let paletteItems = dataSource.getPieceItemsByPieceStates(sorted)
        paletteController.setDataItems(paletteItems)
        
        for stateItem in state.boardPieces {
            if let item = dataSource.getPieceItemById(stateItem.uid) {
                let p = dataSource.getPiece(forItem: item)
//                boardController.addPiece(p)
                scene.board.addPiece(p)
                pcs.append(p)
                p.setPosition(col: stateItem.curX, row: stateItem.curY, rotation: stateItem.rotation)
                p.output = self
            }
        }
        
        let cl = (dataSource.boardSize.verticalSize.width * (col+1)) >= dataSource.difficulty.width
        let rw = (dataSource.boardSize.verticalSize.height * (row+1)) >= dataSource.difficulty.height
        
//        boardController.setBoardPosition(col: col, row: row,
//                                         isColLast: cl, isRowLast: rw,
//                                         puzzleW: lastDataSource.difficulty.width,
//                                         puzzleH: lastDataSource.difficulty.height,
//                                         animated: false)

        scene.board.setBoardPosition(col: col, row: row,
                                     isColLast: cl, isRowLast: rw,
                                     puzzleW: dataSource.difficulty.width,
                                     puzzleH: dataSource.difficulty.height,
                                     animated: false)
        
        pcs.forEach({ (p) in
            self.didSnap(piece: p, initialLoad: true)
        })
    }
    
    func remakeTimer() {
        timer?.invalidate()
        timer = nil
        
        view.gestureRecognizers?.forEach({ (gr) in
            self.view.removeGestureRecognizer(gr)
        })
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PuzzleViewController.didPanTouchView(_:)))
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(PuzzleViewController.checkCompletion), userInfo: nil, repeats: true)
    }
    
    private func setInPlace(items: [PieceItem]) {
        for item in items {
            let p = dataSource.getPiece(forItem: item)
            scene.board.addPiece(p)
            pcs.append(p)
            p.setPosition(col: item.col, row: item.row, rotation: PieceRotation.origin.rawValue)
            p.output = self
            didSnap(piece: p, initialLoad: true)
        }
    }
    
    func setBoardPosition(_ col: Int, row: Int) {
        let items = dataSource.getPieceItems(forBoardColumn: col, boardRow: row)
        
        if lastShuffled {
            paletteController.setDataItems(items.shuffled())
        } else {
            paletteController.setDataItems(items)//no shuffle
        }
        
        setInPlace(items: Array(items.prefix(upTo: 290)))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            
            let dur = (col+row == 0) ? 0.0 : 1.25
            
            let cl = (self.dataSource.boardSize.verticalSize.width * (col+1)) >= self.dataSource.difficulty.width
            let rw = (self.dataSource.boardSize.verticalSize.height * (row+1)) >= self.dataSource.difficulty.height
            
            self.scene.board.setBoardPosition(col: col, row: row,
                                              isColLast: cl, isRowLast: rw,
                                              puzzleW: self.dataSource.difficulty.width,
                                              puzzleH: self.dataSource.difficulty.height,
                                              animated: dur>0) {
                self.sectionTransition = false
            }
            
//            self.boardController.setBoardPosition(col: col, row: row,
//                                                  isColLast: cl, isRowLast: rw,
//                                                  puzzleW: self.lastDataSource.difficulty.width,
//                                                  puzzleH: self.lastDataSource.difficulty.height,
//                                                  animated: dur>0,
//                                                  completion: { () in
//                                                  self.sectionTransition = false
//            })
        })
    }
    
    func hasUncompletedPieces(atCol: Int, row: Int) -> Bool {
        let items = dataSource.getPieceItems(forBoardColumn: atCol, boardRow: row)
        if items.count > 0 {
            let pss = items.filter({ (pi) -> Bool in
                return pi.isUncompleted
            })
            return pss.count > 0
        }
        return false
    }
    
    func didCompleteSection() {
        if let nxt = getNextUncompletedRowCol(fromCol: boardController.col,
                                              fromRow: boardController.row) {
            setBoardPosition(nxt.0, row: nxt.1)
        } else {
            // Puzzle comleted
            timer?.invalidate()
            timer = nil
            
            view.gestureRecognizers?.forEach({ (gr) in
                self.view.removeGestureRecognizer(gr)
            })
            
            boardController.setFinishedState(withCompletion: {
                self.output?.didCompletePuzzle()
            })
        }
    }
    
    func getNextUncompletedRowCol(fromCol: Int, fromRow: Int) -> (Int, Int)? {
        let col = fromCol + ((fromRow%2==0) ? 1 : -1)
        let row = fromRow
        
        if hasUncompletedPieces(atCol: col, row: row) {
            return (col, row)
        } else if hasUncompletedPieces(atCol: fromCol, row: row + 1) {
            return (fromCol, row + 1)
        }
        
        return nil
    }
}
