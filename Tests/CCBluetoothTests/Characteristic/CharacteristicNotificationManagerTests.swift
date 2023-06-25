//
//  CharacteristicNotificationManagerTests.swift
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
import CoreBluetooth
@testable import CCBluetooth

final class CharacteristicNotificationManagerTests: XCTestCase {
    var sut: CCBCharacteristicNotificationManager!
    var subscriptions = Set<AnyCancellable>()
    var peripheralTypeMock: PeripheralTypeMock!

    override func setUp() {
        super.setUp()
        peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connected
        sut = CCBCharacteristicNotificationManager(
            peripheral: peripheralTypeMock
        )
    }

    override func tearDown() {
        subscriptions.forEach { $0.cancel() }
        sut = nil
        super.tearDown()
    }

    func testObserveValueAndSetNotificationCorrect() {
        var delegate: CCBPeripheralSubjects? = CCBPeripheralSubjects()
        peripheralTypeMock.subjects = delegate
        let charateristicType = CharacteristicTypeMock()

        let mockCharacteristic = CCBCharacteristic(
            provider: charateristicType
        )
        var firstSubscriberReceivedData: Data?
        let firstSubscribtion = sut
            .observeValueUpdateAndSetNotification(for: mockCharacteristic)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { firstSubscriberReceivedData = $0.value })

        XCTAssert(peripheralTypeMock.isNotifiedEnabledForCharacteristic[mockCharacteristic.uuid] ?? false)
        let observeExp = expectation(description: #function)
        var secondSubscriberReceivedData: Data?
        let secondSubscription = sut
            .observeValueUpdateAndSetNotification(for: mockCharacteristic)
            .sink(receiveCompletion: { _ in observeExp.fulfill() },
                  receiveValue: { secondSubscriberReceivedData = $0.value })

        XCTAssert(peripheralTypeMock.isNotifiedEnabledForCharacteristic[mockCharacteristic.uuid] ?? false)
        let mockData1 = Data("some data".utf8)
        charateristicType.mockValue = mockData1
        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didUpdateValueFor: charateristicType,
            error: nil
        )
        XCTAssert((firstSubscriberReceivedData == mockData1) && (secondSubscriberReceivedData == mockData1))
        firstSubscribtion.cancel()

        XCTAssert(peripheralTypeMock.isNotifiedEnabledForCharacteristic[mockCharacteristic.uuid] ?? false)
        let mockData2 = Data("some anotehr data".utf8)
        charateristicType.mockValue = mockData2
        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didUpdateValueFor: charateristicType,
            error: nil
        )
        delegate = nil
        secondSubscription.cancel()
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssert((firstSubscriberReceivedData == mockData1) && (secondSubscriberReceivedData == mockData2))
        XCTAssertFalse(peripheralTypeMock.isNotifiedEnabledForCharacteristic[mockCharacteristic.uuid] ?? true)
    }

    func testObserveValueAndSetNotificationNoDelegate() {
        let mockCharacteristic = CCBCharacteristic(
            provider: CharacteristicTypeMock()
        )
        let observeExp = expectation(description: #function)
        let mockError = CCBError.destroyed
        var observeError: CCBError?
        sut
            .observeValueUpdateAndSetNotification(for: mockCharacteristic)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    observeError = error
                    observeExp.fulfill()
                }
            },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(observeError, mockError)
    }

    func testObserveValueAndSetNotificationReceiveError() {
        let delegate: CCBPeripheralSubjects? = CCBPeripheralSubjects()
        peripheralTypeMock.subjects = delegate
        let charateristicType = CharacteristicTypeMock()

        let mockCharacteristic = CCBCharacteristic(
            provider: charateristicType
        )
        let observeExp = expectation(description: #function)
        let error: Error = TestError.someError
        let mockBluetoothError = CCBError
            .characteristicReadFailed(mockCharacteristic, error)
        var observeError: CCBError?

        sut
            .observeValueUpdateAndSetNotification(for: mockCharacteristic)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    observeError = error
                    observeExp.fulfill()
                }
            },
                receiveValue: { _ in })
            .store(in: &subscriptions)
        let mockData = Data("some data".utf8)
        charateristicType.mockValue = mockData
        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didUpdateValueFor: charateristicType,
            error: error
        )
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(observeError, mockBluetoothError)
    }

    private enum TestError: Error {
        case someError
    }
}
