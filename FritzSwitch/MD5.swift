// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG


func MD5(_ messageData: Data) -> Data {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    var digestData = Data(count: length)
    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
        messageData.withUnsafeBytes { messageBytes -> UInt8 in
            if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
            return 0
        }
    }
    return digestData
}

public func makeFritzboxResponse(to challenge: String, authenticatedBy password: String) -> String? {
    guard let utf16le = "\(challenge)-\(password)".data(using: .utf16LittleEndian) else { return nil }
    return MD5(utf16le).map { String(format: "%02hhx", $0) }.joined()
}
