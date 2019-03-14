//  PaletteViewController.swift
//  Created by Vladimir Roganov on 01.05.17.

import UIKit

protocol PaletteInput: class {
    func hoverPiece(_ piece: Piece)
    func setDataItems(_ items: [PieceItem])
    func didGrabItem(_ pieceItem: PieceItem)
    func didReturnToPalette(_ piece: Piece)
    func didPanTouchView(_ pan: UIPanGestureRecognizer)
    func setPaletteBGColor(_ color: UIColor)
}

class PaletteViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PaletteInput, UIGestureRecognizerDelegate {
    
    func unsub() {
        data.removeAll()
        lastItem = nil
        output = nil
        collectionView?.delegate = nil
        collectionView?.dataSource = nil
        collectionView?.removeFromSuperview()
    }
    
    weak var output: PaletteOutput?
    
    var data: [PieceItem] = []
    var scale: CGFloat = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(PaletteCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView?.backgroundColor = UIColor(white: 38.0/255.0, alpha: 1.0)
    }
    
    func setPaletteBGColor(_ color: UIColor) {
        collectionView?.backgroundColor = color
    }
    
    var lastItem: PieceItem? = nil
    var lastPoint: CGPoint!
    func didPanTouchView(_ pan: UIPanGestureRecognizer) {
        if pan.state == .began {
            if lastItem != nil {
                return;
            }
            let pt = pan.location(in: collectionView)
            lastPoint = pt
            if let ip = collectionView?.indexPathForItem(at: pt) {
                if let cell = collectionView?.cellForItem(at: ip) {
                    let tag = cell.contentView.tag
                    if let item = data.filter({$0.uidInt == tag}).first {
                        lastItem = item
                        let nX = pt.x - ((collectionView?.contentOffset.x) ?? 0.0)
                        let nY = pt.y
                        output?.didPick(pieceItem: item,
                                        atPoint: CGPoint(x: nX, y: nY))
                        
                        item.inPalette = false
                        collectionView?.reloadItems(at: [ip])
                    }
                }
            }
        } else if pan.state == .ended
                || pan.state == .cancelled
                || pan.state == .failed {
            if let item = lastItem {
                let pt = pan.location(in: collectionView)
                output?.didDrop(pieceItem: item, atPoint: pt)
            }
            lastItem = nil
        } else if pan.state == .changed {
            if let item = lastItem {
                let pt = pan.location(in: collectionView)
                let delta = CGPoint(x: pt.x-lastPoint.x,
                                    y: pt.y-lastPoint.y)
                lastPoint = pt
                output?.didMove(pieceItem: item, by: delta)
            }
        }
    }
    
    func didGrabItem(_ pieceItem: PieceItem) {
        if let index = data.index(where: {$0.uid == pieceItem.uid}) {
            collectionView?.performBatchUpdates({ [weak self] in
                self?.data.remove(at: index)
                self?.collectionView?.deleteItems(at: [IndexPath(row: index, section: 0)])
                self?.collectionView?.reloadData()
            }, completion: nil)
        }
    }
    
    func didReturnToPalette(_ piece: Piece) {
        guard let cv = collectionView else {
            return
        }
        
        if let index = data.index(where: {$0.uid == piece.item.uid}) {
            let ip = IndexPath(row: index, section: 0)
            if let cell = cv.cellForItem(at: ip) {
                view.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.2, animations: {
                    piece.center = (self.view.window?.convert(cell.contentView.center, from: cell.contentView)) ?? CGPoint.zero
                }, completion: { (finished) in
                    self.view.isUserInteractionEnabled = true
                    if finished {
                        piece.isHidden = true
                        piece.item.inPalette = true
                        self.reloadCellWithPiece(piece)
                    }
                })
            }
        } else {
            // need to insert
            let pt = cv.convert(piece.center, from: piece.superview)
            let ppt = CGPoint(x: pt.x, y: cv.bounds.height * 0.5)
            
            let defIp = (cv.contentOffset.x < 50) ? IndexPath(row: 0, section: 0) : IndexPath(row: cv.numberOfItems(inSection: 0), section: 0)
            
            let ip = cv.indexPathForItem(at: ppt) ?? defIp
            
            if let cell = cv.cellForItem(at: ip) {
                if cell.contentView.tag == piece.item.uidInt {
                    // nothing to do
                    return
                }
            }
            
            cv.performBatchUpdates({
                let ind = self.data.index(where: {$0.uidInt == piece.item.uidInt}) ?? ip.row
                if ind != ip.row {
                    print("swap")
                    // swap
                    self.data.remove(at: ind)
                    cv.deleteItems(at: [IndexPath(row: ind, section: 0)])
                }
                self.data.insert(piece.item, at: ip.row)
                cv.insertItems(at: [ip])
                
                DispatchQueue.main.async {
                    if let cell = cv.cellForItem(at: ip) {
                        self.view.isUserInteractionEnabled = false
                        UIView.animate(withDuration: 0.2, animations: {
                            piece.center = (self.view.window?.convert(cell.contentView.center, from: cell.contentView)) ?? CGPoint.zero
                        }, completion: { [weak self] (finished) in
                            self?.view.isUserInteractionEnabled = true
                            if finished {
                                piece.isHidden = true
                                piece.item.inPalette = true
                                self?.reloadCellWithPiece(piece)
                            }
                        })
                    }
                }
            }, completion: { (finished) in
            })
        }
    }
    
    func reloadCellWithPiece(_ piece: Piece) {
        if let vcs = collectionView?.visibleCells {
            for c in vcs {
                if c.contentView.tag == piece.item.uidInt {
                    if let ip = collectionView?.indexPath(for: c) {
                        collectionView?.reloadItems(at: [ip])
                    }
                    return;
                }
            }
        }
    }
    
    func hoverPiece(_ piece: Piece) {
        guard let cv = collectionView else {
            return
        }
        
        let pt = cv.convert(piece.center, from: piece.superview)
        if pt.x < cv.contentOffset.x
            || pt.y < cv.contentOffset.y
            || pt.x > cv.contentOffset.x + cv.bounds.width
            || pt.y > cv.contentOffset.y + cv.bounds.height {
            // out of bounds
            if let ind = data.index(where: {$0.uidInt == piece.item.uidInt}) {
                let ipToDelete = IndexPath(row: ind, section: 0)
                let size = collectionView(cv, layout: collectionViewLayout, sizeForItemAt: ipToDelete)
                let curX = cv.bounds.width + cv.contentOffset.x
                let maxX = cv.contentSize.width
                let limit = size.width*0.73
                if cv.contentOffset.x > 0 && curX >= maxX - limit {
                    if cv.contentOffset.x > 0 && curX >= maxX - limit*0.2 {
                        lastPoint.x = lastPoint.x - size.width
                    } else if cv.contentOffset.x > 0 && curX >= maxX - limit*0.5 {
                        lastPoint.x = lastPoint.x - size.width * 0.7
                    } else {
                        lastPoint.x = lastPoint.x - size.width * 0.5
                    }
                }
                // need to remove item
                cv.performBatchUpdates({ [weak self] in
                    self?.data.remove(at: ind)
                    cv.deleteItems(at: [ipToDelete])
                }, completion: { (finished) in
                })
            }
        } else {
            let ip = cv.indexPathForItem(at: pt) ?? IndexPath(row: 0, section: 0)
            
            if let cell = cv.cellForItem(at: ip) {
                if cell.contentView.tag == piece.item.uidInt {
                    // nothing to do
                    return
                }
            }
            
            cv.performBatchUpdates({ [weak self] in
                let ind = self?.data.index(where: {$0.uidInt == piece.item.uidInt}) ?? ip.row
                if ind != ip.row {
                    // swap
                    self?.data.remove(at: ind)
                    cv.deleteItems(at: [IndexPath(row: ind, section: 0)])
                }
                self?.data.insert(piece.item, at: ip.row)
                cv.insertItems(at: [ip])
            }, completion: nil)
        }
    }
    
    func setDataItems(_ items: [PieceItem]) {
        var maxSize: CGFloat = 1.0
        let s = CGSize(width: view.bounds.height-8, height: view.bounds.height-8)
        for pi in items {
            let pis = pi.oframe.applying(pi.rotationTransform).size
            let sc = min(s.width / pis.width, s.height / pis.height)
            if sc < maxSize {
                maxSize = sc
            }
        }
        scale = maxSize
        data = items
        collectionView?.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = data[indexPath.row]
        let size = item.oframe.applying(item.rotationTransform.scaledBy(x: scale, y: scale)).size
        return CGSize(width: size.width + 15, height: view.bounds.height)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PaletteCell
        let item = data[indexPath.row]
        cell.contentView.tag = item.uidInt
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        DispatchQueue.main.async { [weak self, weak cell] in
            if let proxy = self?.output?.getProxy(fromItem: item) {
                cell?.setup(withProxy: proxy, item: item)
            }
        }
        return cell
    }
}
