// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation
import AppKit

// MARK: - Double

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - RangeReplaceableCollection

extension RangeReplaceableCollection {
    public mutating func resize(_ size: Int, fillWith value: Iterator.Element) {
        let count = self.count
        if count < size {
            append(contentsOf: repeatElement(value, count: count.distance(to: size)))
        } else if count > size {
            let newEnd = index(startIndex, offsetBy: size)
            removeSubrange(newEnd ..< endIndex)
        }
    }
}
