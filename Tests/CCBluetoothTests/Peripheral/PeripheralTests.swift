//
//  PeripheralTests.swift
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
import XCTest
import CoreBluetooth
import Combine
@testable import CCBluetooth

final class PeripheralTests: XCTestCase {
    var sut: CCBPeripheral!
    var centralManagerMock: CCBCentralManager!
    var centralManagerProviderMock: CentralManagerTypeMock!
    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        centralManagerProviderMock = CentralManagerTypeMock()
        centralManagerProviderMock.state = .poweredOn
        centralManagerMock = CCBCentralManager(
            provider: centralManagerProviderMock,
            subjects: CCBCentralManagerSubjects()
        )
    }

    override func tearDown() {
        subscriptions.forEach { $0.cancel() }
        subscriptions = Set()
        centralManagerMock = nil
        centralManagerProviderMock = nil
        sut = nil
        super.tearDown()
    }

    func testDiscoverServicesEmitsServicesArray() {
        let peripheralTypeMock = PeripheralTypeMock()
        let mockService = CBMutableService(type: CBUUID(),
                                           primary: false)
        peripheralTypeMock.services = [mockService]
        peripheralTypeMock.state = .connected
        let discoverExp = expectation(description: #function)
        var discoveredServices: [CCBService]?
        let mockServices: [CCBService]? = [CCBService(provider: mockService)]

        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        sut
            .discoverServices(nil)
            .sink(receiveCompletion: { _ in discoverExp.fulfill() },
                  receiveValue: { discoveredServices = $0 })
            .store(in: &subscriptions)

        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didDiscoverServices: nil
        )

        centralManagerMock.subjects = nil
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(discoveredServices, mockServices)
    }

    func testDiscoverServicesDisconnectedPeripheral() {
        let peripheralTypeMock = PeripheralTypeMock()
        let mockService = CBMutableService(type: CBUUID(), primary: false)
        peripheralTypeMock.services = [mockService]
        
        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        let mockError = CCBError
            .peripheralDisconnected(sut.identifier, nil)

        let discoverExp = expectation(description: #function)
        var discoverError: CCBError?
        sut
            .discoverServices(nil)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    discoverError = error
                    discoverExp.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &subscriptions)
        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didDiscoverServices: nil
        )

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(discoverError, mockError)
    }

    func testDiscoverCharacteristicsEmitsCharacteristicsArray() {
        let serviceTypeMock = CCBServiceProviderMock()
        let serviceMock = CCBService(provider: serviceTypeMock)
        let peripheralTypeMock = PeripheralTypeMock()
        let mockCharacteristic = serviceTypeMock.characteristics!.first!
        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        let discoverExp = expectation(description: #function)
        var discoveredCharacteristics: [CCBCharacteristic]?
        sut
            .discoverCharacteristics(
                [mockCharacteristic.uuid],
                for: serviceMock
        )
            .sink(receiveCompletion: { _ in discoverExp.fulfill() },
                  receiveValue: { discoveredCharacteristics = $0 })
            .store(in: &subscriptions)

        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didDiscoverCharacteristicsFor: serviceTypeMock,
            error: nil
        )

        sut.subjects = nil
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(discoveredCharacteristics?.first?.uuid,
                       serviceTypeMock.characteristics?.first?.uuid)
    }

    func testReadValueSuccess() {
        let peripheralTypeMock = PeripheralTypeMock()
        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        let characteristicTypeMock = CharacteristicTypeMock()
        let characteristicMock = CCBCharacteristic(
            provider: characteristicTypeMock
        )
        let readExp = expectation(description: #function)
        var readValue: Data?

        sut
            .readValue(for: characteristicMock)
            .sink(receiveCompletion: { _ in readExp.fulfill() },
                  receiveValue: { readValue = $0.value })
            .store(in: &subscriptions)

        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didUpdateValueFor: characteristicTypeMock,
            error: nil)

        sut.subjects = nil
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(readValue, characteristicTypeMock.value)
    }

    func testWriteValueWithResponseSuccess() {
        let peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connected
        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        let characteristicTypeMock = CharacteristicTypeMock()
        let characteristicMock = CCBCharacteristic(
            provider: characteristicTypeMock
        )
        let writeExp = expectation(description: #function)
        writeExp.expectedFulfillmentCount = 2
        var characteristicUUID: CBUUID?
        sut
            .writeValue(Data("mock data".utf8),
                        for: characteristicMock,
                        type: .withResponse)
            .sink(receiveCompletion: { _ in writeExp.fulfill() },
                  receiveValue: { characteristicUUID = $0.uuid })
            .store(in: &subscriptions)

        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didWriteValueFor: characteristicTypeMock,
            error: nil
        )
        sut.subjects = nil
        centralManagerMock.subjects = nil
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(characteristicUUID, characteristicTypeMock.uuid)
    }

    func testWriteValueWithoutResponseSuccess() {
        let peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connected
        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        let characteristicTypeMock = CharacteristicTypeMock()
        let characteristicMock = CCBCharacteristic(
            provider: characteristicTypeMock
        )
        let writeExp = expectation(description: #function)
        var characteristicUUID: CBUUID?

        sut
            .writeValue(Data("mock data".utf8),
                        for: characteristicMock,
                        type: .withoutResponse)
            .sink(receiveCompletion: { _ in writeExp.fulfill() },
                  receiveValue: { characteristicUUID = $0.uuid })
            .store(in: &subscriptions)

        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didWriteValueFor: characteristicTypeMock,
            error: nil
        )
        sut.subjects = nil

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(characteristicUUID, characteristicTypeMock.uuid)
    }

    func testObserveValueUpdateAndSetNotificationSuccess() {
        let peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connected
        sut = CCBPeripheral(manager: centralManagerMock,
                         provider: peripheralTypeMock)
        let characteristicTypeMock = CharacteristicTypeMock()
        let characteristicMock = CCBCharacteristic(
            provider: characteristicTypeMock
        )
        let updateExp = expectation(description: #function)
        updateExp.expectedFulfillmentCount = 2
        var receivedValue: Data?
        let mockValue = Data("some data".utf8)
        characteristicTypeMock.mockValue = mockValue
        sut
            .observeValueUpdateAndSetNotification(for: characteristicMock)
            .sink(receiveCompletion: { _ in updateExp.fulfill() },
                  receiveValue: { receivedValue = $0.value })
            .store(in: &subscriptions)
        peripheralTypeMock.subjects?.peripheral(
            peripheral: peripheralTypeMock,
            didUpdateValueFor: characteristicTypeMock,
            error: nil
        )
        sut.subjects = nil
        centralManagerMock.subjects = nil

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(receivedValue, mockValue)
    }
}
