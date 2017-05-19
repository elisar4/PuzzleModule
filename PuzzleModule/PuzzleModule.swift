//  PuzzleModule.swift
//  Created by Vladimir Roganov on 19.05.17.

import UIKit

public class PuzzleModule
{
    public static func puzzle(atViewController: UIViewController,
                              withDelegate: PuzzleOutput,
                              puzzleImage: UIImage,
                              puzzleRotationEnabled: Bool,
                              puzzleRows: Int,
                              puzzleColumns: Int,
                              puzzlePieces: [[CGPath]],
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.01,
                                      execute: {
            puzzle.configure(withPaths: puzzlePieces,
                             image: puzzleImage,
                             difficulty: difficulty,
                             originSize: puzzleSize)
        })
        
        return puzzle
    }
}
