// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation

let NoSID: String = "0000000000000000"
let MaxSIDAge: TimeInterval = 60 * 60 - 10

enum Key: String {
    case fritzboxHostname
    case fritzboxUsername
    case fritzboxPassword
    case sid
    case sidIssued
}

