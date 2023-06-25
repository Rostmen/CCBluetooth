//
//  Publisher+ShareReplayTests.swift
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

final class ShareReplayTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        subscriptions = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        subscriptions.forEach { $0.cancel() }
        super.tearDown()
    }
    
    func testShareReplayOneForeverScope() {
        let subscription1CompletionExpectation = expectation(
            description: "subscriber1Completion")
        let subscription1ValueExpectation = expectation(
            description: "subscriber1Value")
        subscription1ValueExpectation.expectedFulfillmentCount = 2
        
        let subscription2CompletionExpectation = expectation(
            description: "subscriber2Completion")
        let subscription2ValueExpectation = expectation(
            description: "subscriber2Value")
        subscription2ValueExpectation.expectedFulfillmentCount = 2
        
        let subscription3CompletionExpectation = expectation(
            description: "subscriber3Completion")
        let subscription3ValueExpectation = expectation(
            description: "subscriber3Value")
        subscription3ValueExpectation.expectedFulfillmentCount = 1
        
        let subject = PassthroughSubject<Int, Never>()
        let publisher = subject.shareReplay(1, scope: .forever)
        
        subject.send(0)

        publisher
            .sink(receiveCompletion: { _ in
                subscription1CompletionExpectation.fulfill()
            }, receiveValue: { _ in
                subscription1ValueExpectation.fulfill()
            })
            .store(in: &subscriptions)

        subject.send(1)
        
        publisher
            .sink(receiveCompletion: { _ in
                subscription2CompletionExpectation.fulfill()
            }, receiveValue: { _ in
                subscription2ValueExpectation.fulfill()
            })
            .store(in: &subscriptions)

        subject.send(2)
        subject.send(completion: .finished)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            [unowned self] in
            publisher
                .sink(receiveCompletion: { _ in
                    subscription3CompletionExpectation.fulfill()
                }, receiveValue: { _ in
                    subscription3ValueExpectation.fulfill()
                })
                .store(in: &self.subscriptions)
        }

        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func testShareReplayOneWhileConnectedScope() {
        let subscription1CompletionExpectation = expectation(
            description: "subscriber1Completion")
        let subscription1ValueExpectation = expectation(
            description: "subscriber1Value")
        subscription1ValueExpectation.expectedFulfillmentCount = 2
        
        let subscription2CompletionExpectation = expectation(
            description: "subscriber2Completion")
        let subscription2ValueExpectation = expectation(
            description: "subscriber2Value")
        subscription2ValueExpectation.expectedFulfillmentCount = 2
        
        let subscription3CompletionExpectation = expectation(
            description: "subscriber3Completion")
        
        let subject = PassthroughSubject<Int, Never>()
        let publisher = subject.shareReplay(1, scope: .whileConnected)
        
        subject.send(0)

        publisher
            .sink(receiveCompletion: { _ in
                subscription1CompletionExpectation.fulfill()
            }, receiveValue: { _ in
                subscription1ValueExpectation.fulfill()
            })
            .store(in: &subscriptions)

        subject.send(1)
        
        publisher
            .sink(receiveCompletion: { _ in
                subscription2CompletionExpectation.fulfill()
            }, receiveValue: { _ in
                subscription2ValueExpectation.fulfill()
            })
            .store(in: &subscriptions)

        subject.send(2)
        subject.send(completion: .finished)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
            publisher
                .sink(receiveCompletion: { _ in
                    subscription3CompletionExpectation.fulfill()
                }, receiveValue: { _ in
                    XCTFail("Should not receive values since source completed")
                })
                .store(in: &self.subscriptions)
        }

        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func testShareReplayOneWhileConnectedResubscribe() {
        let subscription1CompletionExpectation = expectation(
            description: "subscriber1Completion")
        let subscription2CompletionExpectation = expectation(
            description: "subscriber2Completion")
        let subscription3CompletionExpectation = expectation(
            description: "subscriber3Completion")
        
        let date = Deferred {
            Future<Date, Never> { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    promise(.success(Date()))
                }
            }
            .eraseToAnyPublisher()
        }
        .shareReplay(1, scope: .whileConnected)
        
        var date1: Date?
        date.sink(receiveCompletion: { _ in
            subscription1CompletionExpectation.fulfill()
        }, receiveValue: { value in
            date1 = value
        }).store(in: &subscriptions)

        var date2: Date?
        date.sink(receiveCompletion: { _ in
            subscription2CompletionExpectation.fulfill()
        }, receiveValue: { value in
            date2 = value
        }).store(in: &subscriptions)

        var date3: Date?
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
            date.sink(receiveCompletion: { _ in
                subscription3CompletionExpectation.fulfill()
            }, receiveValue: { value in
                date3 = value
            }).store(in: &self.subscriptions)
        }
        
        waitForExpectations(timeout: 0.3, handler: nil)
        
        XCTAssertNotNil(date1)
        XCTAssertNotNil(date2)
        XCTAssertNotNil(date3)
        
        XCTAssertEqual(date1, date2)
        XCTAssertNotEqual(date2, date3)
    }
    
    static var allTests = [
        ("testShareReplayOneForeverScope", testShareReplayOneForeverScope),
        ("testShareReplayOneWhileConnectedScope", testShareReplayOneWhileConnectedScope),
        ("testShareReplayOneWhileConnectedResubscribe", testShareReplayOneWhileConnectedResubscribe)
    ]
}
