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
    public static func puzzle(atViewController: UIViewController,
                              withDelegate: PuzzleOutput,
                              puzzleImage: UIImage,
                              puzzleRotationEnabled: Bool,
                              puzzleRows: Int,
                              puzzleColumns: Int,
                              puzzlePieces: Array<Array<UIBezierPath>>,
                              puzzleSize: CGFloat,
                              puzzleInsets: UIEdgeInsets) -> PuzzleViewController
    {
        let puzzle = PuzzleViewController()
        atViewController.addChildViewController(puzzle)
        atViewController.view.addSubview(puzzle.view)
        puzzle.output = withDelegate
        
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
                             image: puzzleImage,
                             difficulty: difficulty,
                             originSize: puzzleSize)
        })
        
        return puzzle
    }
}
