//  PieceItemBuilder.swift
//  Created by Vladimir Roganov on 01.05.17.

import Foundation
import CoreGraphics

class PieceItemBuilder
{
    static func buildItems(withColumns columns: Int, rows: Int, scale: CGFloat, originSize: CGFloat, rotation: Bool, paths: [[CGPath]]) -> [PieceItem]
    {
        let scaledSize = originSize * scale
        var pieceItems: [PieceItem] = []
        for r in 0..<rows
        {
            for c in 0..<columns
            {
                let name = "\(r)-\(c)"
                let path = paths[r][c]
                pieceItems.append(PieceItem(uid: name, row: r, col: c, path: path, scale: scale, size: scaledSize, fixed: !rotation))
            }
        }
        return pieceItems
    }
}
