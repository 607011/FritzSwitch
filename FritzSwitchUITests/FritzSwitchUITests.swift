//
//  FritzSwitchUITests.swift
//  FritzSwitchUITests
//
//  Created by Oliver Lau on 28.06.20.
//  Copyright © 2020 Oliver Lau. All rights reserved.
//

import XCTest

class FritzSwitchUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() {
    }

    func testExample() {
        let app = XCUIApplication()
        app.launch()
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
