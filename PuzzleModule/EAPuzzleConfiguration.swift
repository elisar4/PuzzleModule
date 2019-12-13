//  EAPuzzleConfiguration.swift
//  Created by Vladimir Roganov on 29.04.17.

import Foundation
import CoreGraphics

@objc public class PieceState: NSObject, NSCoding {
    public var uid: String = ""
    public var paletteIndex: Int = -1
    public var curX: Int = 0
    public var curY: Int = 0
    public var rotation: Int = 0
    
    init(from: PieceItem, paletteIndex: Int = -1) {
        super.init()
        
        self.uid = from.uid
        self.curX = from.gridX
        self.curY = from.gridY
        self.rotation = from.rotation.rawValue
        self.paletteIndex = paletteIndex
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.uid, forKey: "uid")
        aCoder.encode(self.curX, forKey: "curX")
        aCoder.encode(self.curY, forKey: "curY")
        aCoder.encode(self.rotation, forKey: "rotation")
        aCoder.encode(self.paletteIndex, forKey: "paletteIndex")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.uid = (aDecoder.decodeObject(forKey: "uid") as? String) ?? ""
        self.curX = aDecoder.decodeInteger(forKey: "curX")
        self.curY = aDecoder.decodeInteger(forKey: "curY")
        self.rotation = aDecoder.decodeInteger(forKey: "rotation")
        self.paletteIndex = aDecoder.decodeInteger(forKey: "paletteIndex")
    }
}

//TODO: try storing state in background thread to make autosaving feature
@objc public class PuzzleState: NSObject, NSCoding {
    @objc public var progress: CGFloat = 0.0
    @objc public var difficulty: Int = 0
    @objc public var rotationEnabled: Bool = false
    //----------------------------------------
    @objc public var boardPositionR: Int = 0
    @objc public var boardPositionC: Int = 0
    //----------------------------------------
    @objc public var boardPieces: [PieceState] = []
    @objc public var palettePieces: [PieceState] = []
    
    init(from: PuzzleViewController) {
        super.init()
        
        self.progress = from.currentProgress
        self.difficulty = from.lastDifficulty.width
        self.rotationEnabled = from.lastDifficulty.rotation
        self.boardPositionR = from.boardController.row
        self.boardPositionC = from.boardController.col
        
        for p in from.pcs {
            self.boardPieces.append(PieceState(from: p.item))
        }
        
        for i in 0..<from.paletteController.data.count {
            let pi = from.paletteController.data[i]
            self.palettePieces.append(PieceState(from: pi, paletteIndex: i))
        }
    }
    
    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(Float(self.progress), forKey: "progress")
        aCoder.encode(self.difficulty, forKey: "difficulty")
        aCoder.encode(self.rotationEnabled, forKey: "rotationEnabled")
        aCoder.encode(self.boardPositionR, forKey: "boardPositionR")
        aCoder.encode(self.boardPositionC, forKey: "boardPositionC")
        aCoder.encode(self.boardPieces, forKey: "boardPieces")
        aCoder.encode(self.palettePieces, forKey: "palettePieces")
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.progress = CGFloat(aDecoder.decodeFloat(forKey: "progress"))
        self.difficulty = aDecoder.decodeInteger(forKey: "difficulty")
        self.rotationEnabled = aDecoder.decodeBool(forKey: "rotationEnabled")
        self.boardPositionR = aDecoder.decodeInteger(forKey: "boardPositionR")
        self.boardPositionC = aDecoder.decodeInteger(forKey: "boardPositionC")
        self.boardPieces = (aDecoder.decodeObject(forKey: "boardPieces") as? [PieceState]) ?? [PieceState]()
        self.palettePieces = (aDecoder.decodeObject(forKey: "palettePieces") as? [PieceState]) ?? [PieceState]()
    }
}

class EAPuzzle {
    public let config: EAPuzzleConfiguration
    public let progress: EAPuzzleProgress = EAPuzzleProgress()
    
    init(withConfig config: EAPuzzleConfiguration) {
        self.config = config
    }
}

class EAPuzzleConfiguration {
    public let originSize: Float
    public let difficulty: EAPuzzleDifficulty
    public var board: EAPuzzleBoard
    
    init(withDifficulty: EAPuzzleDifficulty, board: EAPuzzleBoard, originSize: Float) {
        self.originSize = originSize
        self.difficulty = withDifficulty
        self.board = board
    }
}

@objc class EAPuzzleDifficulty: NSObject {
    public let width: Int
    public let height: Int
    public let rotation: Bool
    
    init(withPiecesColumns piecesColumns: Int, piecesRows: Int, rotationEnabled: Bool) {
        self.width = piecesColumns
        self.height = piecesRows
        self.rotation = rotationEnabled
    }
}

class EAPuzzleBoardSize {
    public let width: Int
    public let height: Int
    
    init(withWidth width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

class EAPuzzleBoard {
    public let horizontalSize: EAPuzzleBoardSize
    public let verticalSize: EAPuzzleBoardSize
    
    init(withHorizontalSize horizontalSize: EAPuzzleBoardSize, verticalSize: EAPuzzleBoardSize) {
        self.horizontalSize = horizontalSize
        self.verticalSize = verticalSize
    }
}

class EAPuzzleProgress {
    public var onBoardPieces: [String:(x: Int, y: Int, r: Float)] = [:]
    public var completedPieces: [String] = []
}
