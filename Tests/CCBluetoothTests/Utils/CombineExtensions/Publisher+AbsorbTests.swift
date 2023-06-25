//
//  Publisher+AbsorbTests.swift
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

import Foundation
import Combine
import XCTest

@testable import CCBluetooth

class AbsorbTests: XCTestCase {
    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        subscriptions = Set()
    }
    
    override func tearDown() {
        super.tearDown()
        subscriptions.forEach { $0.cancel() }
    }
    
    func testReceiveValues() {
        let subj1 = PassthroughSubject<Int, Never>()
        let subj2 = PassthroughSubject<Int, Never>()
        
        var result = [Int]()
        let exp = expectation(description: "testReceiveValues")
        subj1.absorb(subj2).collect().sink(receiveValue: {
            result = $0
            exp.fulfill()
            }).store(in: &subscriptions)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            subj1.send(1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
            subj1.send(3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(15)) {
            subj2.send(2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(25)) {
            subj1.send(completion: .finished)
            subj2.send(completion: .finished)
        }
        
        waitForExpectations(timeout: 0.03, handler: nil)
        XCTAssertEqual(result, [1, 2, 3])
    }
    
    func testReceiveError() {
        enum E: Int, Error { case some }
        let subj1 = PassthroughSubject<Int, E>()
        let subj2 = PassthroughSubject<Int, E>()
        
        var result = [Int]()
        var completion: Subscribers.Completion<E>? = nil
        let exp = expectation(description: "testReceiveError")
        
        subj1.absorb(subj2).sink(receiveCompletion: {
            exp.fulfill()
            completion = $0
        }, receiveValue: {
            result.append($0)
            }).store(in: &subscriptions)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            subj1.send(1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
            subj1.send(completion: .failure(.some))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(15)) {
            subj2.send(2)
        }
        
        waitForExpectations(timeout: 0.03, handler: nil)
        XCTAssertEqual(result, [1, 2])
        XCTAssertEqual(completion, .some(.failure(.some)))
    }
    
    static var allTests = [
        ("testReceiveValues", testReceiveValues),
        ("testReceiveError", testReceiveError)
    ]
}
