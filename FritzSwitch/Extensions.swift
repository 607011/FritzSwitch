// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation

// MARK: - Double

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
