//  Shuffle.swift
//  Created by Vladimir Roganov on 06/12/2018.

import CoreGraphics

extension MutableCollection where Indices.Iterator.Element == Index {
    
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            swapAt(firstUnshuffled, index(firstUnshuffled, offsetBy: d))
        }
    }
}

extension Sequence {
    
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

extension CGRect {
    
    func cliped(with: CGRect) -> CGRect {
        let p = min(with.width / width, with.height / height)
        let newW = width * p
        let newH = height * p
        return CGRect(x: (with.width - newW) * 0.5,
                      y: (with.height - newH) * 0.5,
                      width: newW,
                      height: newH)
    }
}

extension CGSize {
    var reversed: CGSize {
        return CGSize(width: height, height: width)
    }
}
