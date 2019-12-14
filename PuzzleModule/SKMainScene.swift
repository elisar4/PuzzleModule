//  SKMainScene.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKMainScene: SKScene {
    
    let palette = SKPaletteNode(texture: nil, color: UIColor.systemPink, size: CGSize(width: UIScreen.main.bounds.width, height: 94.0))
    
    override init(size: CGSize) {
        super.init(size: size)
        defaultInit()
    }
    
    private func defaultInit() {
        backgroundColor = UIColor.systemOrange
        scaleMode = .resizeFill
        
        addChild(palette)
        palette.anchorPoint = .zero
        palette.position = .zero
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
