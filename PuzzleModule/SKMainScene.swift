//  SKMainScene.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKMainScene: SKScene {
    
    static let PaletteHeight: CGFloat = 94.0
    
    lazy var board: SKBoardNode = {
        let h = self.size.height - Self.PaletteHeight
        return SKBoardNode(texture: nil, color: UIColor.systemRed.withAlphaComponent(0.5), size: CGSize(width: self.size.width, height: h))
    } ()
    
    let palette = SKPaletteNode(texture: nil, color: UIColor.systemPink.withAlphaComponent(0.5), size: CGSize(width: UIScreen.main.bounds.width, height: SKMainScene.PaletteHeight))
    
    override init(size: CGSize) {
        super.init(size: size)
        defaultInit()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        let h = size.height - Self.PaletteHeight
        board.size = CGSize(width: size.width, height: h)
        board.didUpdateSize()
    }
    
    private func defaultInit() {
        backgroundColor = UIColor.black
        scaleMode = .resizeFill
        
        addChild(board)
        board.position = CGPoint(x: 0, y: Self.PaletteHeight)
        
        addChild(palette)
        palette.position = .zero
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
