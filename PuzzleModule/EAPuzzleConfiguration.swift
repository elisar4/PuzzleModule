//  EAPuzzleConfiguration.swift
//  Created by Vladimir Roganov on 29.04.17.

import Foundation

class EAPuzzle
{
    public let config: EAPuzzleConfiguration
    public let progress: EAPuzzleProgress = EAPuzzleProgress()
    
    init(withConfig config: EAPuzzleConfiguration)
    {
        self.config = config
        
    }
}

class EAPuzzleConfiguration
{
    public let originSize: Float
    public let difficulty: EAPuzzleDifficulty
    public var board: EAPuzzleBoard
    
    init(withDifficulty: EAPuzzleDifficulty, board: EAPuzzleBoard, originSize: Float)
    {
        self.originSize = originSize
        self.difficulty = withDifficulty
        self.board = board
    }
}

class EAPuzzleDifficulty
{
    public let width: Int
    public let height: Int
    public let rotation: Bool
    
    init(withPiecesColumns piecesColumns: Int, piecesRows: Int, rotationEnabled: Bool)
    {
        self.width = piecesColumns
        self.height = piecesRows
        self.rotation = rotationEnabled
    }
}

class EAPuzzleBoardSize
{
    public let width: Int
    public let height: Int
    
    init(withWidth width: Int, height: Int)
    {
        self.width = width
        self.height = height
    }
}

class EAPuzzleBoard
{
    public let horizontalSize: EAPuzzleBoardSize
    public let verticalSize: EAPuzzleBoardSize
    
    init(withHorizontalSize horizontalSize: EAPuzzleBoardSize, verticalSize: EAPuzzleBoardSize)
    {
        self.horizontalSize = horizontalSize
        self.verticalSize = verticalSize
    }
}

class EAPuzzleProgress
{
    public var onBoardPieces: [String:(x: Int, y: Int, r: Float)] = [:]
    public var completedPieces: [String] = []
}
