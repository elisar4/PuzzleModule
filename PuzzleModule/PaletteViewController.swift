//  PaletteViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

protocol PaletteOutput: class
{
    func getProxy(fromItem: PieceItem) -> UIImageView
    func getProxyAsync(fromItem: PieceItem, completion: @escaping (UIImageView)->())
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
    func setPaletteBGColor(_ color: UIColor)
}

class PaletteCell: UICollectionViewCell
{
    
}

class PaletteViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PaletteInput, UIGestureRecognizerDelegate
{
    
    func unsub()
    {
        self.data.removeAll()
        self.lastItem = nil
    }
    
    weak var output: PaletteOutput?
    
    var data: [PieceItem] = []
    var scale: CGFloat = 1.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.collectionView?.register(PaletteCell.self, forCellWithReuseIdentifier: "Cell")

        self.collectionView?.backgroundColor = UIColor(white: 38.0/255.0, alpha: 1.0)
    }
    
    func setPaletteBGColor(_ color: UIColor)
    {
        self.collectionView?.backgroundColor = color
    }
    
    var lastItem: PieceItem? = nil
    var lastPoint: CGPoint!
    func didPanTouchView(_ pan: UIPanGestureRecognizer)
    {
        if pan.state == .began
        {
            if self.lastItem != nil
            {
                return;
            }
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
                || pan.state == .cancelled
                || pan.state == .failed
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
                self.view.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.2, animations: {
                    piece.center = (self.view.window?.convert(cell.contentView.center, from: cell.contentView)) ?? CGPoint.zero
                }, completion: { (finished) in
                    self.view.isUserInteractionEnabled = true
                    if finished
                    {
                        piece.isHidden = true
                        piece.item.inPalette = true
                        self.reloadCellWithPiece(piece)
                    }
                })
            }
        } else
        {
            // need to insert
            let pt = cv.convert(piece.center, from: piece.superview)
            let ppt = CGPoint(x: pt.x, y: cv.bounds.height * 0.5)
            
            let defIp = (cv.contentOffset.x < 50) ? IndexPath(row: 0, section: 0) : IndexPath(row: cv.numberOfItems(inSection: 0), section: 0)
            
            let ip = cv.indexPathForItem(at: ppt) ?? defIp
            
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
                    print("swap")
                    // swap
                    self.data.remove(at: ind)
                    cv.deleteItems(at: [IndexPath(row: ind, section: 0)])
                }
                self.data.insert(piece.item, at: ip.row)
                cv.insertItems(at: [ip])
                
                DispatchQueue.main.async {
                    if let cell = cv.cellForItem(at: ip)
                    {
                        self.view.isUserInteractionEnabled = false
                        UIView.animate(withDuration: 0.2, animations: {
                            piece.center = (self.view.window?.convert(cell.contentView.center, from: cell.contentView)) ?? CGPoint.zero
                        }, completion: { (finished) in
                            self.view.isUserInteractionEnabled = true
                            if finished
                            {
                                piece.isHidden = true
                                piece.item.inPalette = true
                                self.reloadCellWithPiece(piece)
                            }
                        })
                    }
                }
                
            }, completion: { (finished) in
            })
        }
    }
    
    func reloadCellWithPiece(_ piece: Piece)
    {
        if let vcs = self.collectionView?.visibleCells
        {
            for c in vcs
            {
                if c.contentView.tag == piece.item.uidInt
                {
                    if let ip = self.collectionView?.indexPath(for: c)
                    {
                        self.collectionView?.reloadItems(at: [ip])
                    }
                    return;
                }
            }
        }
    }
    
    func hoverPiece(_ piece: Piece)
    {
        guard let cv = self.collectionView else {
            return
        }
        
        let pt = cv.convert(piece.center, from: piece.superview)
        if pt.x < cv.contentOffset.x
            || pt.y < cv.contentOffset.y
            || pt.x > cv.contentOffset.x + cv.bounds.width
            || pt.y > cv.contentOffset.y + cv.bounds.height
        {
            // out of bounds
            if let ind = self.data.index(where: {$0.uidInt == piece.item.uidInt})
            {
                let ipToDelete = IndexPath(row: ind, section: 0)
                let size = self.collectionView(cv, layout: self.collectionViewLayout, sizeForItemAt: ipToDelete)
                let curX = cv.bounds.width + cv.contentOffset.x
                let maxX = cv.contentSize.width
                let limit = size.width*0.73
                if cv.contentOffset.x > 0 && curX >= maxX - limit {
                    if cv.contentOffset.x > 0 && curX >= maxX - limit*0.2 {
                        self.lastPoint.x = self.lastPoint.x - size.width
                    } else if cv.contentOffset.x > 0 && curX >= maxX - limit*0.5 {
                        self.lastPoint.x = self.lastPoint.x - size.width * 0.7
                    } else {
                        self.lastPoint.x = self.lastPoint.x - size.width * 0.5
                    }
                }
                // need to remove item
                cv.performBatchUpdates({
                    self.data.remove(at: ind)
                    cv.deleteItems(at: [ipToDelete])
                }, completion: { (finished) in
                })
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
    
    func setDataItems(_ items: [PieceItem]) {
        var maxSize: CGFloat = 1.0
        let s = CGSize(width: view.bounds.height-8, height: view.bounds.height-8)
        for pi in items {
            let pis = pi.rosizeCorrected
            print("#123:", pis)
            let sc = min(s.width / pis.width, s.height / pis.height)
            if sc < maxSize {
                maxSize = sc
            }
        }
        self.scale = maxSize
        self.data = items
        self.collectionView?.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.data[indexPath.row]
        let rs = item.rosizeCorrected
        let size = CGSize(width: rs.width*self.scale, height: rs.height*self.scale)
        return CGSize(width: size.width+15,
                      height: self.view.bounds.height)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    
    var animCnt = 0
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PaletteCell
        
        let item = self.data[indexPath.row]
        
        cell.contentView.tag = item.uidInt
        
        self.output?.getProxyAsync(fromItem: item,
                                   completion: { (proxy) in
            if cell.contentView.tag == proxy.tag
            {
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                
                cell.contentView.addSubview(proxy)
                
                proxy.alpha = 0.0
                
                var b = cell.contentView.bounds
                b.size.width -= 10
                let ros = item.rosizeCorrected
                let newFrame = CGRect(x: 0, y: 0, width: ros.width*self.scale, height: ros.height*self.scale)
                proxy.bounds = newFrame
                
                print("#111", newFrame)
                
                proxy.mAnchor = CGPoint(x: 0.5, y: 0.5)
                
                proxy.center = cell.contentView.center
                
                proxy.transform = CGAffineTransform.identity.rotated(by: item.rotation.angle)
                
                proxy.isHidden = !item.inPalette
                
                let delay = min(0.15, max(0, Double(self.animCnt)*0.033))
                
                self.animCnt += 1
                
                UIView.animate(withDuration: 0.35, delay: delay, options: [], animations: {
                    proxy.alpha = 1.0
                }, completion: { (finished) in
                    if finished {
                        self.animCnt -= 1
                    }
                })
            }
        })
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
