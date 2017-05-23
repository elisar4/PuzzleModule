//  PaletteViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

protocol PaletteOutput: class
{
    func getProxy(fromItem: PieceItem) -> UIImageView
    func didPick(pieceItem: PieceItem, atPoint: CGPoint)
    func didMove(pieceItem: PieceItem, by: CGPoint)
    func didDrop(pieceItem: PieceItem, atPoint: CGPoint)
}

protocol PaletteInput: class
{
    func hoverPiece(_ piece: Piece)
    func setDataItems(_ items: [PieceItem])
    func didGrabItem(_ pieceItem: PieceItem)
    func didReturnToPalette(_ piece: Piece)
    func didPanTouchView(_ pan: UIPanGestureRecognizer)
}

class PaletteCell: UICollectionViewCell
{
    
}

class PaletteViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PaletteInput, UIGestureRecognizerDelegate
{
    weak var output: PaletteOutput?
    
    var data: [PieceItem] = []
    var scale: CGFloat = 1.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.collectionView?.register(PaletteCell.self, forCellWithReuseIdentifier: "Cell")

        self.collectionView?.backgroundColor = UIColor(white: 38.0/255.0, alpha: 1.0)
        
        print("palette did load")
    }
    
    var lastItem: PieceItem?
    var lastPoint: CGPoint!
    func didPanTouchView(_ pan: UIPanGestureRecognizer)
    {
        if pan.state == .began
        {
            let pt = pan.location(in: collectionView)
            self.lastPoint = pt
            if let ip = collectionView?.indexPathForItem(at: pt)
            {
                if let cell = self.collectionView?.cellForItem(at: ip)
                {
                    let tag = cell.contentView.tag
                    if let item = self.data.filter({$0.uidInt == tag}).first
                    {
                        self.lastItem = item
                        let nX = pt.x - ((self.collectionView?.contentOffset.x) ?? 0.0)
                        let nY = pt.y
                        self.output?.didPick(pieceItem: item,
                                             atPoint: CGPoint(x: nX, y: nY))
                        
                        item.inPalette = false
                        self.collectionView?.reloadItems(at: [ip])
                    }
                }
            }
        } else if pan.state == .ended
        {
            if let item = self.lastItem
            {
                let pt = pan.location(in: collectionView)
                self.output?.didDrop(pieceItem: item, atPoint: pt)
            }
            self.lastItem = nil
        } else if pan.state == .changed
        {
            if let item = self.lastItem
            {
                let pt = pan.location(in: collectionView)
                let delta = CGPoint(x: pt.x-self.lastPoint.x,
                                    y: pt.y-self.lastPoint.y)
                self.lastPoint = pt
                self.output?.didMove(pieceItem: item, by: delta)
            }
        }
    }
    
    func didGrabItem(_ pieceItem: PieceItem)
    {
        if let index = self.data.index(where: {$0.uid == pieceItem.uid})
        {
            let ip = IndexPath(row: index, section: 0)
            self.collectionView?.performBatchUpdates({
                self.data.remove(at: index)
                self.collectionView?.deleteItems(at: [ip])
                self.collectionView?.reloadData()
            }, completion: nil)
        }
    }
    
    func didReturnToPalette(_ piece: Piece)
    {
        guard let cv = self.collectionView else {
            return
        }
        
        if let index = self.data.index(where: {$0.uid == piece.item.uid})
        {
            let ip = IndexPath(row: index, section: 0)
            if let cell = cv.cellForItem(at: ip)
            {
                UIView.animate(withDuration: 0.22, animations: { 
                    piece.center = (self.view.window?.convert(cell.contentView.center, from: cell.contentView)) ?? CGPoint.zero
                }, completion: { (finished) in
                    if finished
                    {
                        piece.isHidden = true
                        piece.item.inPalette = true
                        cv.reloadItems(at: [ip])
                    }
                })
            }
        } else
        {
            // need to insert
            
            let pt = cv.convert(piece.center, from: piece.superview)
            let ppt = CGPoint(x: pt.x, y: cv.bounds.height * 0.5)
            
            let ip = cv.indexPathForItem(at: ppt) ?? IndexPath(row: 0, section: 0)
            
            if let cell = cv.cellForItem(at: ip)
            {
                if cell.contentView.tag == piece.item.uidInt
                {
                    // nothing to do
                    return
                }
            }
            
            cv.performBatchUpdates({
                let ind = self.data.index(where: {$0.uidInt == piece.item.uidInt}) ?? ip.row
                if ind != ip.row
                {
                    // swap
                    self.data.remove(at: ind)
                    cv.deleteItems(at: [IndexPath(row: ind, section: 0)])
                }
                self.data.insert(piece.item, at: ip.row)
                cv.insertItems(at: [ip])
                
                DispatchQueue.main.async {
                    
                    if let index = self.data.index(where: {$0.uid == piece.item.uid})
                    {
                        let ip = IndexPath(row: index, section: 0)
                        if let cell = cv.cellForItem(at: ip)
                        {
                            UIView.animate(withDuration: 0.22, animations: {
                                piece.center = (self.view.window?.convert(cell.contentView.center, from: cell.contentView)) ?? CGPoint.zero
                            }, completion: { (finished) in
                                if finished
                                {
                                    piece.isHidden = true
                                    piece.item.inPalette = true
                                    cv.reloadItems(at: [ip])
                                }
                            })
                        }
                    }
                }
            }, completion: nil)
            
        }
    }
    
    func hoverPiece(_ piece: Piece)
    {
        guard let cv = self.collectionView else {
            return
        }
        
        let pt = cv.convert(piece.center, from: piece.superview)
        //print(pt, cv.contentOffset)
        if pt.x < cv.contentOffset.x
            || pt.y < cv.contentOffset.y
            || pt.x > cv.contentOffset.x + cv.bounds.width
            || pt.y > cv.contentOffset.y + cv.bounds.height
        {
            // out of bounds
            //print("oob ")
            if let ind = self.data.index(where: {$0.uidInt == piece.item.uidInt})
            {
                // need to remove item
                cv.performBatchUpdates({
                    self.data.remove(at: ind)
                    cv.deleteItems(at: [IndexPath(row: ind, section: 0)])
                }, completion: nil)
            }
        } else
        {
            let ip = cv.indexPathForItem(at: pt) ?? IndexPath(row: 0, section: 0)
            
            if let cell = cv.cellForItem(at: ip)
            {
                if cell.contentView.tag == piece.item.uidInt
                {
                    // nothing to do
                    return
                }
            }
            
            cv.performBatchUpdates({
                let ind = self.data.index(where: {$0.uidInt == piece.item.uidInt}) ?? ip.row
                if ind != ip.row
                {
                    // swap
                    self.data.remove(at: ind)
                    cv.deleteItems(at: [IndexPath(row: ind, section: 0)])
                }
                self.data.insert(piece.item, at: ip.row)
                cv.insertItems(at: [ip])
            }, completion: nil)
        }
    }
    
    func setDataItems(_ items: [PieceItem])
    {
        var maxSize: CGFloat = 1.0
        let s = CGSize(width: self.view.bounds.height-8, height: self.view.bounds.height-8)
        for pi in items
        {
            let pis = pi.oframe.applying(pi.rotationTransform).size
            
            let sc = min(s.width / pis.width, s.height / pis.height)
            if sc < maxSize
            {
                maxSize = sc
            }
        }
        self.scale = maxSize
        self.data = items
        self.collectionView?.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let item = self.data[indexPath.row]
        let size = item.oframe.applying(item.rotationTransform.scaledBy(x: self.scale, y: self.scale)).size
        return CGSize(width: size.width+15,
                      height: self.view.bounds.height)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.data.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PaletteCell
        
        let item = self.data[indexPath.row]
        
        DispatchQueue.main.async {
            
            if let proxy = self.output?.getProxy(fromItem: item)
            {
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                
                cell.contentView.addSubview(proxy)
                cell.contentView.tag = proxy.tag
                
                var b = cell.contentView.bounds
                b.size.width -= 10
                let newFrame = item.oframe.applying(CGAffineTransform.identity.rotated(by: item.rotation.angle)).cliped(with: b)
                
                if item.rotation == .left || item.rotation == .right
                {
                    proxy.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: newFrame.size.height, height: newFrame.size.width))
                } else
                {
                    proxy.bounds = CGRect(origin: CGPoint.zero, size: newFrame.size)
                }
                
                proxy.mAnchor = CGPoint(x: 0.5, y: 0.5)
                
                proxy.center = cell.contentView.center
                
                proxy.transform = CGAffineTransform.identity.rotated(by: item.rotation.angle)
                
                proxy.isHidden = !item.inPalette
            }
        }
        return cell
    }
}

extension CGRect
{
    func cliped(with: CGRect) -> CGRect
    {
        let p = min(with.width/self.width, with.height/self.height)
        
        let newW = self.width * p
        let newH = self.height * p
        
        return CGRect(x: (with.width - newW) * 0.5, y: (with.height - newH) * 0.5, width: newW, height: newH)
    }
}
