//  SKBoardNode.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKPieceContainer: SKSpriteNode {
    
}

class SKBoardNode: SKSpriteNode {
    
    let container = SKPieceContainer(texture: nil, color: UIColor.yellow.withAlphaComponent(0.5), size: CGSize(width: 3800, height: 3800))
    
    var board: EAPuzzleBoard?
    var originSize: CGFloat = 0.0
    
    var base = SKNode()
    
    var bgNode = SKSpriteNode()
    
    var border = SKShapeNode()
    
    var col: Int = -1
    var row: Int = -1
    
    var maxCol: Int = 0
    var maxRow: Int = 0
    
    var animating: Bool = false
    
    func setBoardSize(_ boardSize: EAPuzzleBoard, originSize: CGFloat) {
        board = boardSize
        self.originSize = originSize
    }
    
    func setBackgroundImage(_ image: UIImage, withMaxCols: Int, maxRows: Int) {
        self.maxCol = withMaxCols
        self.maxRow = maxRows
        
        let mx = CGFloat(withMaxCols) * originSize
        let my = CGFloat(maxRows) * originSize
        
        bgNode.size = CGSize(width: mx, height: my)
        bgNode.texture = SKTexture(image: image)
        
        container.size = CGSize(width: mx, height: my)
        
        border.path = UIBezierPath(rect: CGRect(x: 4, y: 4, width: mx - 8, height: my - 8)).cgPath
        border.position = CGPoint(x: 0, y: -my)
    }
    
    func didUpdateSize() {
        base.position = CGPoint(x: 0, y: size.height)
        
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        border.strokeColor = UIColor(white: 1.0, alpha: 0.4)
        border.fillColor = UIColor.clear
        border.lineWidth = 7.5
        border.zPosition = 500
        
        bgNode.anchorPoint = CGPoint(x: 0, y: 1)
        bgNode.alpha = 1.0
        
        //backgroundColor = UIColor(white: 80.0/255.0, alpha: 1.0)
        addChild(base)
        base.position = CGPoint(x: 0, y: size.height)
        
        base.addChild(bgNode)
        
        anchorPoint = .zero
        
        container.anchorPoint = CGPoint(x: 0, y: 1)
        base.addChild(container)
        container.position = .zero
        
        container.addChild(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
