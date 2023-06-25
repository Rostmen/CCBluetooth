//
//  Publisher+RetryWhenTests.swift
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

final class RetryWhenTests: XCTestCase {
    enum Failure: Error {
        case retry
    }
    func testPassthroughValue() {
        let expectation = XCTestExpectation(description: "testPassthroughValue")

        let subject = PassthroughSubject<Int, Error>()

        let completion = subject
            .retryWhen { input -> Empty<Int, Error> in Empty<Int, Error>() }
            .sink(receiveCompletion: { _ in }, receiveValue: {
                XCTAssertEqual($0, 5)
                expectation.fulfill()
            })

        subject.send(5)

        wait(for: [expectation], timeout: 1.0)
        completion.cancel()
    }

    func testHandlerCalledOnError() {
        let expectation = XCTestExpectation(
            description: "testHandlerCalledOnError"
        )

        let subject = PassthroughSubject<Int, Error>()

        let handler: (AnyPublisher<Error, Never>) -> Fail<Int, Error> = { _ in
            expectation.fulfill()
            return Fail(error: Failure.retry)
        }

        let completion = subject.retryWhen(handler)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTFail()
            })

        subject.send(completion: .failure(Failure.retry))

        wait(for: [expectation], timeout: 1.0)
        completion.cancel()
    }

    func testPublisherResubscribed() {
        let expectation = XCTestExpectation(
            description: "testPublisherResubscribed"
        )
        
        var first = true
        let deferredPublisher = Deferred {
            Future<Int, Failure> { promise in
                if first {
                    promise(.failure(.retry))
                    first = false
                } else {
                    promise(.success(1))
                }
            }
        }.eraseToAnyPublisher()

        let handler: (AnyPublisher<Failure, Never>) -> AnyPublisher<Void, Failure> =
        { input in
            return input
                .setFailureType(to: Failure.self)
                .flatMap { _ in
                    Just(()).setFailureType(to: Failure.self)
                }
                .eraseToAnyPublisher()
        }

        let completion = deferredPublisher.retryWhen(handler)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                XCTAssertEqual($0, 1)
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 1.0)
        completion.cancel()
    }
    
    func testSequence() {
        func makeSuccess() -> AnyPublisher<Void, Error> {
            Deferred { Future { $0(.success(())) } } .eraseToAnyPublisher()
        }
        
        func makeError() -> AnyPublisher<Void, Error> {
            var retries: Int = 0
            return Deferred {
                Future { promise in
                    defer { retries += 1 }
                    if retries > 2 {
                        promise(.success(()))
                    } else {
                        promise(.failure(Failure.retry))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        
        func handler(errors: AnyPublisher<Error, Never>) -> AnyPublisher<Void, Error> {
            errors.setFailureType(to: Error.self).flatMap { e -> AnyPublisher<Void, Error> in
                if case Failure.retry = e {
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                } else {
                    return Fail<Void, Error>(error: e).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
        }
        
        let exp = expectation(description: "wait until finish")
        let operations = [
            makeSuccess(),
            makeError().retryWhen(handler).eraseToAnyPublisher(),
            makeSuccess()
        ]
        
        let subscription = operations
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { $0 }
            .map { _ in 1 }.reduce(0, +).sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("\(error)")
                } else {
                    exp.fulfill()
                }
            } receiveValue: {
                XCTAssertEqual($0, operations.count)
            }

        waitForExpectations(timeout: 1, handler: nil)
        subscription.cancel()
    }
    
    static var allTests = [
        ("testPassthroughValue", testPassthroughValue),
        ("testHandlerCalledOnError", testHandlerCalledOnError),
        ("testPublisherResubscribed", testPublisherResubscribed),
        ("testSequence", testSequence)
    ]
}
