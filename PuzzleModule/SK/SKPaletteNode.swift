//  SKPaletteNode.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKPaletteNode: SKSpriteNode {
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        anchorPoint = .zero
        zPosition = 1000
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
