//  SKMainScene.swift
//  Created by Vladimir Roganov on 14.12.2019.

import SpriteKit

class SKMainScene: SKScene {
    
    static let PaletteHeight: CGFloat = 94.0
    
    lazy var board: SKBoardNode = {
        let h = self.size.height - Self.PaletteHeight
        return SKBoardNode(texture: nil, color: UIColor.black, size: CGSize(width: self.size.width, height: h))
    } ()
    
    let palette = SKPaletteNode(texture: nil, color: UIColor.systemPink.withAlphaComponent(0.5), size: CGSize(width: UIScreen.main.bounds.width, height: SKMainScene.PaletteHeight))
    
    override init(size: CGSize) {
        super.init(size: size)
        defaultInit()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        view.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        let h = size.height - Self.PaletteHeight
        board.size = CGSize(width: size.width, height: h)
        board.didUpdateSize()
    }
    
    var targetPiece: SKPiece?
    @objc private func onPan(_ sender: UIPanGestureRecognizer) {
        let loc = sender.location(in: view)
        let ll = CGPoint(x: loc.x, y: size.height - loc.y)
        let l = convert(ll, to: board.container)
        
        switch sender.state {
        case .began:
            if let p = board.piece(at: l), p.canPan {
                
                print("pan began", l, p)
                p.beginPan()
                targetPiece = p
            }
            
        case .changed:
            let translation = sender.translation(in: view)
            sender.setTranslation(CGPoint.zero, in: view)
            targetPiece?.movePan(translation)
            
        case .cancelled, .ended, .failed:
            targetPiece?.endPan()
            
        default:
            break
        }
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        let loc = sender.location(in: view)
        let ll = CGPoint(x: loc.x, y: size.height - loc.y)
        let l = convert(ll, to: board.container)
        if let p = board.piece(at: l) {
            p.tap()
        }
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
