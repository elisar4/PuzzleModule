//  SKBoardNode.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKPieceContainer: SKSpriteNode {
    
}

class SKBoardNode: SKSpriteNode {
    
    let container = SKPieceContainer(texture: nil, color: UIColor.yellow, size: CGSize(width: 3800, height: 3800))
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        anchorPoint = .zero
        addChild(container)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
