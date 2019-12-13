//  PuzzleInput.swift
//  Created by Vladimir Roganov on 06/12/2018.

import UIKit

@objc protocol PuzzleInput: class {
    func configure(withPaths: [[CGPath]], frames: [[CGRect]], image: UIImage, difficulty: EAPuzzleDifficulty, originSize: CGFloat, w: Int, h: Int, puzzleState: PuzzleState?, shuffle: Bool, boardBGColor: UIColor?, paletteBGColor: UIColor?)
    
    func storePuzzleState() -> PuzzleState
    
    func setBoardImageVisible(_ val: Bool)
    
    func setBGColors(_ board: UIColor?, _ palette: UIColor?)
    
    func deinitPuzzle()
}

extension PuzzleViewController: PuzzleInput {
    
    public func setBoardImageVisible(_ val: Bool) {
        boardController.setBoardImageVisible(val)
    }
    
    public func storePuzzleState() -> PuzzleState {
        return PuzzleState(from: self)
    }
    
    
    func setBGColors(_ board: UIColor?, _ palette: UIColor?) {
        if let board = board {
            boardController.setBoardBGColor(board)
        }
        
        if let palette = palette {
            paletteController.setPaletteBGColor(palette)
        }
    }
    
    func configure(withPaths: [[CGPath]], frames: [[CGRect]], image: UIImage, difficulty: EAPuzzleDifficulty, originSize: CGFloat, w: Int, h: Int, puzzleState: PuzzleState?, shuffle: Bool, boardBGColor: UIColor?, paletteBGColor: UIColor?) {
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
        
        setBGColors(boardBGColor, paletteBGColor)
        
        let vertical = EAPuzzleBoardSize(withWidth: w,
                                         height: h)
        let horizontal = EAPuzzleBoardSize(withWidth: vertical.height,
                                           height: vertical.width)
        
        let boardSize = EAPuzzleBoard(withHorizontalSize: horizontal,
                                      verticalSize: vertical)
        
        let pieces: CGFloat = CGFloat(boardSize.verticalSize.width)
        let vPieces: CGFloat = CGFloat(boardSize.verticalSize.height)
        
        let bs = self.boardSize
        
        let www = bs.width / (pieces + 0.5)
        let hhh = bs.height / (vPieces + 0.5)
        
        let scale: CGFloat
        if www <= hhh {
            scale = www / originSize
        } else {
            scale = hhh / originSize
        }
        
        let s = (originSize * scale) * CGFloat(difficulty.width) / image.size.width
        
        let img = image.resizedImage(scale: s)
        
        let dataSource = PuzzleDataSource(withPiecePaths: withPaths, frames: frames, difficulty: difficulty, scale: scale, originSize: originSize, boardSize: boardSize, puzzleImage: self.imgWithBorder(img))
        lastDataSource = dataSource
        
        boardController.setBoardSize(boardSize, originSize: originSize * scale)
        
        boardController.setBackgroundImage(img, withMaxCols: difficulty.width, maxRows: difficulty.height)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            
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
    
    private func imgWithBorder(_ image: UIImage) -> UIImage {
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
    
    public func deinitPuzzle() {
        view.gestureRecognizers?.forEach({ [weak self] (gr) in
            self?.view.removeGestureRecognizer(gr)
        })
        
        timer?.invalidate()
        timer = nil
        
        pcs.forEach { (p) in
            p.unsub()
        }
        gr.forEach { (pg) in
            pg.unsub()
        }
        pcs.removeAll()
        gr.removeAll()
        
        boardController.unsub()
        paletteController.unsub()
        
        lastDataSource?.unsub()
        
        lastImage = nil
        
        lastPaths.removeAll()
    }
}
