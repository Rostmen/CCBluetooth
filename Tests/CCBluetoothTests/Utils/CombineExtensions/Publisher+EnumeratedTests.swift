//
//  Publisher+EnumeratedTests.swift
//  CCBluetoothTests
//
//  Created by Rostyslav Kobyzskyi on 2023.
//  Copyright (c) 2023 Rostyslav Kobyzskyi. All rights reserved.
//  This file is part of CCBluetooth.
//
//  CCBluetooth is free software: you can redistribute it and/or modify
//  it under the terms of the MIT License as published by
//  the Open Source Initiative.
//
//  CCBluetooth is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  MIT License for more details.
//
//  You should have received a copy of the MIT License along with CCBluetooth.
//  If not, see <https://opensource.org/licenses/MIT>.
//


import XCTest
import Combine
@testable import CCBluetooth

final class EnumeratedTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        subscriptions.forEach { $0.cancel() }
        super.tearDown()
    }
    
    func testEnumeration() {
        let source = ["a", "b", "c"].publisher.enumerated()
        let subscription1CompletionExpectation = expectation(
            description: "subscriber1Completion"
        )
        
        var result: [Int] = []
        source
            .map { $0.0 }
            .collect()
            .sink(receiveCompletion: { _ in
                subscription1CompletionExpectation.fulfill()
            }, receiveValue: {
                result = $0
            })
            .store(in: &subscriptions)
        
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(result, [0, 1, 2])
    }
    
    func testEnumerationUniqueEnumerator() {
        let source = ["a", "b", "c"].publisher.enumerated()
        let subscription1CompletionExpectation = expectation(
            description: "subscriber1Completion"
        )
        let subscription2CompletionExpectation = expectation(
            description: "subscriber1Completion"
        )
        
        var result1: [Int] = []
        source
            .map { $0.0 }
            .collect()
            .sink(receiveCompletion: { _ in
                subscription1CompletionExpectation.fulfill()
            }, receiveValue: {
                result1 = $0
            })
            .store(in: &subscriptions)
        
        var result2: [Int] = []
        source
            .map { $0.0 }
            .collect()
            .sink(receiveCompletion: { _ in
                subscription2CompletionExpectation.fulfill()
            }, receiveValue: {
                result2 = $0
            })
            .store(in: &subscriptions)
        
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(result1, result2)
    }
    
    static var allTests = [
        ("testEnumeration", testEnumeration),
        ("testEnumerationUniqueEnumerator", testEnumerationUniqueEnumerator)
    ]
}

