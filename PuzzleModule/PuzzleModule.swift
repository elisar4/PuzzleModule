//  PuzzleModule.swift
//  Created by Vladimir Roganov on 19.05.17.

import UIKit

//
//preload proxys?
//
//bug with zLayout when drop from palette
//
//pick piece from palette bug: then drag last piece & contentSize changes
//
//add piece effects
//
//bug with board moving not linear
//
//feature: section navigation via zoom
//

@objc public class PuzzleModule: NSObject
{
    static var insets: UIEdgeInsets = .zero
    
    @objc public static func puzzle(atViewController: UIViewController,
                              withDelegate: PuzzleOutput,
                              puzzleImage: UIImage,
                              puzzleRotationEnabled: Bool,
                              puzzleRows: Int,
                              puzzleColumns: Int,
                              boardRows: Int,
                              boardColumns: Int,
                              puzzlePieces: Array<Array<UIBezierPath>>,
                              puzzleFrames: Array<Array<CGRect>>,
                              puzzleSize: CGFloat,
                              puzzleInsets: UIEdgeInsets,
                              puzzleState: PuzzleState?,
                              shuffle: Bool,
                              boardBGColor: UIColor?,
                              paletteBGColor: UIColor?) -> PuzzleViewController
    {
        let puzzle = PuzzleViewController()
        atViewController.addChild(puzzle)
        atViewController.view.addSubview(puzzle.view)
        puzzle.output = withDelegate
        
        puzzle.setBGColors(boardBGColor, paletteBGColor)
        
        insets = puzzleInsets
        
        puzzle.view.fillSuperView(puzzleInsets)
        
        let difficulty = EAPuzzleDifficulty(withPiecesColumns: puzzleColumns,
                                            piecesRows: puzzleRows,
                                            rotationEnabled: puzzleRotationEnabled)
        
        let pieces = puzzlePieces.map { (pp) -> [CGPath] in
            return pp.map({ (p) -> CGPath in
                return p.cgPath
            })
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.01,
                                      execute: {
            puzzle.configure(withPaths: pieces,
                             frames: puzzleFrames,
                             image: puzzleImage,
                             difficulty: difficulty,
                             originSize: puzzleSize,
                             w: boardColumns,
                             h: boardRows,
                             puzzleState: puzzleState,
                             shuffle: shuffle,
                             boardBGColor: boardBGColor,
                             paletteBGColor: paletteBGColor)
        })
        
        return puzzle
    }
}
