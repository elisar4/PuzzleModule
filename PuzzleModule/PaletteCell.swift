//  PaletteCell.swift
//  Created by Vladimir Roganov on 12/03/2019.

import UIKit

class PaletteCell: UICollectionViewCell {
    func setup(withProxy proxy: UIImageView, item: PieceItem) {
        if contentView.tag == proxy.tag {
            contentView.addSubview(proxy)
            let b = contentView.bounds.insetBy(dx: 5, dy: 0)
            let newSize = item.oframe.applying(CGAffineTransform.identity.rotated(by: item.rotation.angle)).cliped(with: b).size
            if item.rotation == .left || item.rotation == .right {
                proxy.frame = CGRect(origin: .zero, size: newSize.reversed)
            } else {
                proxy.frame = CGRect(origin: .zero, size: newSize)
            }
            proxy.mAnchor = CGPoint(x: 0.5, y: 0.5)
            proxy.center = contentView.center
            proxy.transform = CGAffineTransform.identity.rotated(by: item.rotation.angle)
            proxy.isHidden = !item.inPalette
        }
    }
}
