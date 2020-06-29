//
//  FritzSwitchTests.swift
//  FritzSwitchTests
//
//  Created by Oliver Lau on 28.06.20.
//  Copyright © 2020 Oliver Lau. All rights reserved.
//

import XCTest
import CommonCrypto
@testable import FritzSwitch

class FritzSwitchTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResponse() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let challenge = "1234567z"
        let pwd = "äbc"
        let response = makeFritzboxResponse(challenge: challenge, password: pwd)
        XCTAssertNotNil(response)
        XCTAssertEqual("\(challenge)-\(response ?? "")", "1234567z-9e224a41eeefa284df7bb0f26c2913e2")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
