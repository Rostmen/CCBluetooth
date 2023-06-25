//
//  CCBCentralManager.swift
//  CCBluetooth
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
import CoreBluetooth

/// `CCBCentralManager` is a public class responsible for managing a centralized CBManager.
public class CCBCentralManager {
    /// The underlying `CCBCentralManagerType` instance that provides the actual implementation of the CBManager.
    internal var provider: CCBCentralManagerProvider

    /// An instance of `CCBCentralManagerSubjects`, which acts as the delegate for the CBManager.
    internal var subjects: CCBCentralManagerSubjects?

    /// The state of the underlying `provider` CBManager.
    public var state: CBManagerState { provider.state }

    /// Initializes a new `CCBCentralManager` with the provided `CCBCentralManagerProvider`
    /// and `CCBCentralManagerSubjects`.
    ///
    /// - Parameters:
    ///   - provider: The `CCBCentralManagerProvider` instance to use for the actual CBManager functionality.
    ///   - delegate: The `CCBCentralManagerSubjects` instance to use for handling CBManager events.
    internal required init(
        provider: CCBCentralManagerProvider,
        subjects: CCBCentralManagerSubjects
    ) {
        self.provider = provider
        self.subjects = subjects
    }

    /// Convenience initializer that creates a new `CCBCentralManager` with the provided dispatch queue and options.
    ///
    /// - Parameters:
    ///   - queue: The dispatch queue to use for delivering CBManager events. If nil, events are delivered on a main queue.
    ///   - options: A dictionary to customize the behavior of the CBManager.
    public convenience init(queue: DispatchQueue? = nil, options: [String : Any]) {
        let subjects = CCBCentralManagerSubjects()
        let manager = CBCentralManager(delegate: subjects, queue: queue, options: options)
        self.init(provider: manager, subjects: subjects)
    }

    /// Returns a publisher that emits events whenever the central manager's state changes.
    public func observeState() -> CCBPublisher<CBManagerState> {
        subjects.map {
            $0
                .didUpdateStateSubject
                .map(\.state)
                .setFailureType(to: CCBError.self)
                .eraseToAnyPublisher()
        } ?? .error(.destroyed)
    }

    /// Initiates a scan for peripherals that offer a specified service.
    ///
    /// - Parameters:
    ///   - services: The services to scan for, specified by UUID.
    ///   - options: Options for the scan, specified as a dictionary of values.
    public func scan(
        services: [CBUUID]?,
        options: [String : Any]? = nil
    ) -> CCBPublisher<CCBScanResult> {
        Deferred { [weak self] () -> CCBPublisher<CCBScanResult> in
            guard let self = self, let delegateWrapper = self.subjects else {
                return .error(.destroyed)
            }

            guard !self.provider.isScanning else {
                return .error(.scanInProgress)
            }

            let scanning = delegateWrapper
                .didDiscoverSubject
                .setFailureType(to: CCBError.self)
                .map(self.makeConvertedScanResult)
                .map(CCBScanResult.init)
                .mapError(CCBError.init)

            return self
                .ensure(state: .poweredOn, source: scanning)
                .handleEvents(receiveSubscription: { [weak self] _ in
                    self?.provider.scanForPeripherals(
                        withServices: services,
                        options: options
                    )
                }, receiveCompletion: { [weak self] _ in
                    self?.provider.stopScan()
                }, receiveCancel: { [weak self] in
                    self?.provider.stopScan()
                })
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    /// A typealias for a tuple representing the results of a peripheral scan once converted to usable data.
    typealias ConvertedScanResult = (CCBPeripheral, CCBAdvertisementData, NSNumber)

    /// Converts raw scan data into a `ConvertedScanResult`.
    ///
    /// - Parameters:
    ///   - manager: The central manager that produced the data.
    ///   - peripheral: The discovered peripheral.
    ///   - advertisementData: The advertisement data broadcast by the peripheral.
    ///   - rssi: The signal strength of the peripheral.
    private func makeConvertedScanResult(
        manager: CCBCentralManagerProvider,
        peripheral: CCBPeripheralProvider,
        ads: [String: Any],
        rssi: NSNumber
    ) -> ConvertedScanResult {
        (CCBPeripheral(manager: self,provider: peripheral), CCBAdvertisementData(ads), rssi)
    }

    /// Establishes a connection to a given peripheral.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral to connect to.
    ///   - options: Optional connection parameters.
    public func establishConnection(
        peripheral: CCBPeripheral,
        options: [String : Any]? = nil
    ) -> CCBPublisher<CCBPeripheral> {
        Deferred { [weak self] () -> CCBPublisher<CCBPeripheral> in
            guard
                let self = self,
                let delegateWrapper = self.subjects
            else {
                return Fail(error: CCBError.destroyed)
                    .eraseToAnyPublisher()
            }

            if peripheral.state == .connected {
                return Just(peripheral)
                    .setFailureType(to: CCBError.self)
                    .eraseToAnyPublisher()
            }

            if peripheral.state == .connecting {
                return Fail(error: CCBError
                    .peripheralIsAlreadyConnecting(peripheral.identifier))
                .eraseToAnyPublisher()
            }

            let onDisconnect = self.makeDidiDisconnectPublisher(
                identifier: peripheral.identifier,
                delegateWrapper: delegateWrapper
            )

            let onFailToConnect = self.observeOnFailToConnect(
                identifier: peripheral.identifier,
                delegateWrapper: delegateWrapper
            )

            let disconnection = onDisconnect.amb(onFailToConnect)

            let connection = delegateWrapper
                .didConnectSubject
                .setFailureType(to: CCBError.self)
                .filter { $0.1.identifier == peripheral.identifier }
                .map { [weak self] in (self, $0.1) }
                .map( CCBPeripheral.init )
                .handleEvents(receiveSubscription: { [weak self] _ in
                    self?.provider.connect(peripheral.provider, options: options)
                })
                .absorb(disconnection)

            return self.ensure(
                state: .poweredOn,
                source: peripheral.state == .disconnecting
                ? disconnection.flatMap { _ in connection }.eraseToAnyPublisher()
                : connection.eraseToAnyPublisher()
            )
        }
        .handleEvents(receiveCompletion: { [provider] _ in
            provider.cancelPeripheralConnection(peripheral.provider)
        }, receiveCancel: { [provider] in
            provider.cancelPeripheralConnection(peripheral.provider)
        })
        .eraseToAnyPublisher()
    }

    /// Returns a publisher that emits a peripheral upon failure to connect.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the peripheral.
    ///   - subjects: The delegate wrapper to use.
    func observeOnFailToConnect(
        identifier: UUID,
        delegateWrapper: CCBCentralManagerSubjects
    ) -> CCBPublisher<CCBPeripheral> {
        delegateWrapper
            .didFailToConnectSubject
            .filter { $0.1.identifier == identifier }
            .map { [weak self] in (self, $0.1, $0.2) }
            .tryMap(CCBPeripheral.init)
            .mapError(CCBError.init)
            .eraseToAnyPublisher()
    }

    /// Ensures that the current state is correct before emitting items from a publisher.
    ///
    /// - Parameters:
    ///   - state: The expected state.
    ///   - source: The source publisher.
    func ensure<P: Publisher>(
        state: CBManagerState,
        source: P
    ) -> AnyPublisher<P.Output, P.Failure> where P.Failure == CCBError {
        subjects.map {
            $0
                .didUpdateStateSubject.map(\.state)
                .prepend(provider.state)
                .filter { $0 != state && CCBError(state: $0) != nil }
                .tryMap { state -> P.Output in throw CCBError(state: state)! }
                .mapError(CCBError.init)
                .absorb(source)
                .eraseToAnyPublisher()
        } ?? .error(.destroyed)
    }

    /// Returns a publisher that emits a peripheral upon disconnection.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the peripheral.
    ///   - subjects: The delegate wrapper to use.
    func makeDidiDisconnectPublisher(
        identifier: UUID,
        delegateWrapper: CCBCentralManagerSubjects
    ) -> CCBPublisher<CCBPeripheral> {
        delegateWrapper
            .didDisconnectPeripheralSubject
            .filter { $0.1.identifier == identifier }
            .tryMap { result -> CCBPeripheral in
                throw CCBError.peripheralDisconnected(identifier, result.2)
            }
            .mapError(CCBError.init)
            .eraseToAnyPublisher()
    }

    /// Ensures that a peripheral is connected before emitting items from a publisher.
    ///
    /// - Parameter peripheral: The peripheral to check.
    func ensurePeripheralIsConnected<T>(
        _ peripheral: CCBPeripheral
    ) -> CCBPublisher<T> {
        Deferred { [weak self] () -> CCBPublisher<T> in
            peripheral.isConnected
            ? self?.subjects.map {
                $0
                    .didDisconnectPeripheralSubject
                    .filter { $0.1.identifier == peripheral.identifier }
                    .tryMap { result in
                        throw CCBError.peripheralDisconnected(peripheral.identifier, result.2)
                    }
                    .mapError(CCBError.init)
                    .eraseToAnyPublisher()
            } ?? .error(.destroyed)
            : .error(.peripheralDisconnected(peripheral.identifier, nil))
        }
        .eraseToAnyPublisher()
    }
}
