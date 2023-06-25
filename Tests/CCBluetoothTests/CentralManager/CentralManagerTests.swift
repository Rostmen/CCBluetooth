//
//  CentralManagerTests.swift
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

final class CentralManagerTests: XCTestCase {
    var sut: CCBCentralManager!
    var providerMock: CentralManagerTypeMock!
    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        providerMock = CentralManagerTypeMock()
        sut = CCBCentralManager(
            provider: providerMock,
            subjects: CCBCentralManagerSubjects()
        )
    }

    override func tearDown() {
        subscriptions.forEach { $0.cancel() }
        providerMock = nil
        sut = nil
        super.tearDown()
    }

    func testChangeStateCorrect() {
        let stateExp = expectation(description: #function)
        var receivedState: CBManagerState?
        sut
            .observeState()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { state in
                    receivedState = state
                    stateExp.fulfill()
            })
            .store(in: &subscriptions)
        providerMock.state = .poweredOff
        sut.subjects?.centralManagerDidUpdateState(central: providerMock)
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(receivedState,
                       providerMock.state)
    }

    func testCorrectScan() {
        let peripheralTypeMock = PeripheralTypeMock()
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )

        let scanExp = expectation(description: #function)
        scanExp.expectedFulfillmentCount = 2

        let advertisementData: [String: Any] = [:]

        let expectedScanResult: CCBScanResult = CCBScanResult(
            peripheral: mockPeripheral,
            advertisementData: CCBAdvertisementData(advertisementData),
            rssi: 1
        )
        var scanResultPeripheral: CCBScanResult?
        sut
            .scan(services: nil)
            .sink(receiveCompletion: { _ in scanExp.fulfill() },
                  receiveValue: { scanResultPeripheral = $0 })
            .store(in: &subscriptions)
        sut.subjects?.centralManager(
            central: providerMock,
            didDiscover: peripheralTypeMock,
            advertisementData: advertisementData,
            rssi: 1
        )
        sut.subjects = nil

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(scanResultPeripheral,
                       expectedScanResult)

        XCTAssertEqual(scanResultPeripheral?.advertisementData,
                       expectedScanResult.advertisementData)
    }

    func testScanInProgress() {
        providerMock.isScanning = true

        let scanExp = expectation(description: #function)
        var scanError: CCBError?
        let mockError = CCBError.scanInProgress
        sut
            .scan(services: nil)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    scanError = error
                    scanExp.fulfill()
                }
            },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(scanError, mockError)
    }

    func testCorrectConnectToPeripheral() {
        let peripheralTypeMock = PeripheralTypeMock()
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )
        let connectExp = expectation(description: #function)
        connectExp.expectedFulfillmentCount = 2
        var connectedPeripheral: CCBPeripheral?

        sut
            .establishConnection(peripheral: mockPeripheral)
            .sink(receiveCompletion: { _ in connectExp.fulfill() },
                  receiveValue: { connectedPeripheral = $0 })
            .store(in: &subscriptions)

        sut.subjects?.centralManager(
            central: providerMock,
            didConnect: peripheralTypeMock
        )
        sut.subjects = nil

        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(connectedPeripheral, mockPeripheral)
    }

    func testConnectToConnectedPeripheral() {
        let peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connected
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )
        let connectExp = expectation(description: #function)
        var connectedPeripheral: CCBPeripheral?

        sut
            .establishConnection(peripheral: mockPeripheral)
            .sink(receiveCompletion: { _ in connectExp.fulfill() },
                  receiveValue: { connectedPeripheral = $0 })
            .store(in: &subscriptions)
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(connectedPeripheral, mockPeripheral)
    }

    func testConnectoToConnectingPeripheral() {
        let peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connecting
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )
        let connectExp = expectation(description: #function)
        var connectError: CCBError?
        let mockError = CCBError
            .peripheralIsAlreadyConnecting(mockPeripheral.identifier)
        sut
            .establishConnection(peripheral: mockPeripheral)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    connectError = error
                    connectExp.fulfill()
                }
            },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        sut.subjects?.centralManager(
            central: providerMock,
            didConnect: peripheralTypeMock
        )

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(connectError, mockError)
    }

    func testCreateDidiDisconnectPublisher() {
        let peripheralTypeMock = PeripheralTypeMock()
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )
        let mockError = CCBError
            .peripheralDisconnected(mockPeripheral.identifier, nil)
        let disconnectExp = expectation(description: #function)
        var disconnectError: CCBError?
        sut
            .makeDidiDisconnectPublisher(
                identifier: peripheralTypeMock.identifier,
                delegateWrapper: sut.subjects!
        )
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    disconnectError = error
                    disconnectExp.fulfill()
                }
            },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        sut.subjects?.centralManager(
            central: providerMock,
            didDisconnectPeripheral: peripheralTypeMock,
            error: nil)
        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(disconnectError, mockError)
    }

    func testCreateOnFailToConnect() {
        let peripheralTypeMock = PeripheralTypeMock()
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )
        let mockError = CCBError.peripheralFailedToConnect(
            mockPeripheral.identifier, nil
        )
        let connectExp = expectation(description: #function)
        var connectError: CCBError?
        sut
            .observeOnFailToConnect(identifier: peripheralTypeMock.identifier,
                                   delegateWrapper: sut.subjects!)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    connectError = error
                    connectExp.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &subscriptions)

        sut.subjects?.centralManager(
            central: providerMock,
            didFailToConnect: peripheralTypeMock,
            error: mockError)

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(connectError, mockError)
    }

    func testEnsurePeripheralIsConnectedFailed() {
        let peripheralTypeMock = PeripheralTypeMock()
        peripheralTypeMock.state = .connected
        let mockPeripheral = CCBPeripheral(
            manager: sut,
            provider: peripheralTypeMock
        )

        let connectExp = expectation(description: #function)
        var connectError: CCBError?
        let mockError = CCBError.peripheralDisconnected(
            mockPeripheral.identifier, nil
        )
        let pub: CCBPublisher<Void> = sut
            .ensurePeripheralIsConnected(mockPeripheral)

        pub.sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    connectError = error
                    connectExp.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &subscriptions)
        sut.subjects?.centralManager(
            central: providerMock,
            didDisconnectPeripheral: peripheralTypeMock,
            error: mockError
        )

        waitForExpectations(timeout: 0.01, handler: nil)
        XCTAssertEqual(connectError, connectError)
    }
}
