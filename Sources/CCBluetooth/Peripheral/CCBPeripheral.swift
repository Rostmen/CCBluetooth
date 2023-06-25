//
//  CCBPeripheral.swift
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

/// `CCBPeripheral` is a class that wraps a peripheral device in the Bluetooth framework.
public class CCBPeripheral {
    /// The provider of peripheral-related functionalities.
    var provider: CCBPeripheralProvider

    /// The delegate wrapper that handles peripheral-specific events.
    var delegateWrapper: CCBPeripheralSubjects?

    /// The manager that handles characteristic notifications.
    private let notificationManager: CCBCharacteristicNotificationManager

    /// The manager that manages the Bluetooth central device.
    weak var manager: CCBCentralManager?

    /// The local name of the peripheral.
    public var name: String? { provider.name }

    /// The current received signal strength indicator (RSSI) of the peripheral, in decibels.
    public var rssi: NSNumber? { provider.rssi }

    /// The current connection state of the peripheral.
    public var state: CBPeripheralState { provider.state }

    /// The unique identifier (UUID) of the peripheral.
    public var identifier: UUID { provider.identifier }

    /// A Boolean value indicating whether the peripheral can send more write without response operations.
    public var canSendWriteWithoutResponse: Bool { provider.canSendWriteWithoutResponse }

    /// A Boolean value indicating whether the peripheral is connected.
    public var isConnected: Bool { provider.state == .connected }

    /// Initializes a new peripheral.
    /// - Parameters:
    ///   - manager: The manager that manages the Bluetooth central device.
    ///   - provider: The provider of peripheral-related functionalities.
    ///   - subjects: The delegate wrapper that handles peripheral-specific events.
    ///   - notificationManager: The manager that handles characteristic notifications.
    init(manager: CCBCentralManager?, provider: CCBPeripheralProvider,
         delegateWrapper: CCBPeripheralSubjects,
         notificationManager: CCBCharacteristicNotificationManager
    ) {
        self.manager = manager
        self.provider = provider
        self.provider.subjects = delegateWrapper
        self.delegateWrapper = delegateWrapper
        self.notificationManager = notificationManager
    }

    /// Initializes a new peripheral with the provided manager and provider.
    /// - Parameters:
    ///   - manager: The manager that manages the Bluetooth central device.
    ///   - provider: The provider of peripheral-related functionalities.
    convenience init(manager: CCBCentralManager?, provider: CCBPeripheralProvider) {
        self.init(manager: manager, provider: provider, delegateWrapper: .init(),
                  notificationManager: .init(peripheral: provider))
    }

    /// Discovers the services of the peripheral.
    /// - Parameters:
    ///  - serviceUUIDs: An array of `CBUUID` objects that you are interested in.
    ///  Here, each `CBUUID` object represents a service UUID.
    /// - Returns: Publisher with collection of discovered services.
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) -> CCBPublisher<[CCBService]> {
        Deferred { [weak self, identifier] () -> CCBPublisher<[CCBService]> in
            guard
                let self = self,
                let manager = self.manager,
                let delegateWrapper = self.delegateWrapper
            else {
                return .error(.destroyed)
            }
            if self.state != .connected {
                return .error(.peripheralDisconnected(identifier, nil))
            }

            return manager.ensure(
                state: .poweredOn,
                source: delegateWrapper
                    .didDiscoverServicesSubject
                    .services(identifier: identifier)
            )
        }
        .handleEvents(receiveSubscription: { [weak self] _ in
            guard let self = self else { return }
            if self.provider.subjects == nil {
                self.provider.subjects = self.delegateWrapper
            }
            self.provider.discoverServices(serviceUUIDs)
        })
        .eraseToAnyPublisher()
    }

    /// Discovers the specified characteristics of a service.
    /// - Parameters:
    ///   - characteristicUUIDs: An array of `CBUUID` objects that you are interested in.
    ///   Here, each `CBUUID` object represents a characteristic UUID.
    ///   - service: The `CCBServiceProvider` that specifies the service of the characteristics.
    /// - Returns: Publisher with collection of discovered characteristics.
    public func discoverCharacteristics(
        _ characteristicUUIDs: [CBUUID]?,
        for service: CCBServiceProvider
    ) -> CCBPublisher<[CCBCharacteristic]> {
        Deferred { [weak self] () -> CCBPublisher<[CCBCharacteristic]> in
            guard let self = self, let delegateWrapper = self.delegateWrapper else {
                return .error(.destroyed)
            }

            return delegateWrapper
                .didDiscoverCharacteristicsForServiceSubject
                .characteristics(serviceUUID: service.uuid)
                .handleEvents(receiveSubscription: { [weak self] _ in
                    self?.provider.discoverCharacteristics(characteristicUUIDs, for: service)
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Reads the value of a specified characteristic.
    /// - Parameter characteristic: The `CCBCharacteristic` that specifies the characteristic.
    /// - Returns: Publisher with updated characteristic value.
    public func readValue(
        for characteristic: CCBCharacteristic
    ) -> CCBPublisher<CCBCharacteristic> {
        Deferred { [weak self] () -> CCBPublisher<CCBCharacteristic> in
            guard let self = self, let delegateWrapper = self.delegateWrapper else {
                return .error(.destroyed)
            }
            return delegateWrapper
                .didUpdateValueForCharacteristicSubject
                .characteristic(
                    uuid: characteristic.uuid,
                    mapError: { .characteristicReadFailed($0, $1) }
                )
                .handleEvents(receiveSubscription: { [weak self] _ in
                    self?.provider.readValue(for: characteristic.provider)
                })
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Sets up notifications or indications for the value of a specified characteristic.
    /// - Parameter characteristic: The `CCBCharacteristic` that specifies the characteristic.
    /// - Returns: Publisher with updated characteristic value.
    public func observeValueUpdateAndSetNotification(
        for characteristic: CCBCharacteristic
    ) -> CCBPublisher<CCBCharacteristic> {
        manager.map {
            $0.ensure(
                state: .poweredOn,
                source: notificationManager
                    .observeValueUpdateAndSetNotification(for: characteristic)
            )
        } ?? Fail(error: CCBError.destroyed).eraseToAnyPublisher()
    }

    /// Writes the value of a characteristic.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - characteristic: The `CCBCharacteristic` that specifies the characteristic.
    ///   - type: The write type for the characteristic.
    /// - Returns: Publisher with updated characteristic.
    public func writeValue(
        _ data: Data,
        for characteristic: CCBCharacteristic,
        type: CBCharacteristicWriteType
    ) -> CCBPublisher<CCBCharacteristic> {
        Deferred { [weak self] () -> CCBPublisher<CCBCharacteristic> in
            guard let self = self, let delegateWrapper = self.delegateWrapper else {
                return .error(.destroyed)
            }
            switch type {
                case .withoutResponse:
                    return delegateWrapper
                        .peripheralIsReadyToSendWriteWithoutResponseSubject
                        .map { _ in true }
                        .prepend(self.canSendWriteWithoutResponse)
                        .filter { $0 }
                        .first()
                        .setFailureType(to: CCBError.self)
                        .map { _ in .just(.init(provider: characteristic.provider)) }
                        .flatMap(self.ensureValidPeripheralState)
                        .eraseToAnyPublisher()
                case .withResponse:
                    return self.ensureValidPeripheralState(
                        for: delegateWrapper
                            .peripheralDidWriteValueForCharacteristicSubject
                            .characteristic(
                                uuid: characteristic.uuid,
                                mapError: { .characteristicWriteFailed($0, $1) }
                            )
                    )
                    .eraseToAnyPublisher()
                @unknown default:
                    return .error(.unknownWriteType)
            }
        }
        .handleEvents(receiveSubscription: { [weak self] _ in
            self?.provider.writeValue(data, for: characteristic.provider, type: type)
        })
        .eraseToAnyPublisher()
    }

    /// Helper function to ensure the valid peripheral state for a given publisher.
    /// - Parameter publisher: The publisher to check the peripheral state for.
    private func ensureValidPeripheralState<T>(for publisher: CCBPublisher<T>) -> CCBPublisher<T> {
        manager.map { unwrapped in
            unwrapped
                .ensurePeripheralIsConnected(self)
                .absorb(unwrapped
                    .ensure(state: .poweredOn, source: publisher)
                    .eraseToAnyPublisher())
                .eraseToAnyPublisher()
        } ?? .error(.destroyed)
    }
}

/// An extension that provides additional initializers for `CCBPeripheral`.
extension CCBPeripheral {
    /// Initializes a new peripheral, throwing an error if there was a problem.
    /// - Parameters:
    ///   - manager: The manager that manages the Bluetooth central device.
    ///   - provider: The provider of peripheral-related functionalities.
    ///   - error: An optional error that may have occurred.
    /// - Throws: A `CCBError.peripheralFailedToConnect` if there is a provided error.
    convenience init(
        manager: CCBCentralManager?,
        provider: CCBPeripheralProvider,
        error: Error?
    ) throws {
        guard error == nil else {
            throw CCBError.peripheralFailedToConnect(provider.identifier, error)
        }
        self.init(manager: manager, provider: provider)
    }
}

/// An extension that provides equatability for `CCBPeripheral`.
extension CCBPeripheral: Equatable {
    /// Returns a Boolean value indicating whether two peripherals are equal.
    /// - Parameters:
    ///   - lhs: A peripheral to compare.
    ///   - rhs: Another peripheral to compare.
    public static func == (lhs: CCBPeripheral, rhs: CCBPeripheral) -> Bool {
        return lhs.provider.identifier == rhs.provider.identifier
    }
}

/// An extension that provides helper methods for publishers with an output
/// of `PeripheralDelegateWrapper.DidDiscoverCharacteristicsForService`.
extension Publisher where Output == CCBPeripheralSubjects.DidDiscoverCharacteristicsForService {

    /// Returns a publisher that filters and maps the discovered characteristics for a service.
    /// - Parameter serviceUUID: The UUID of the service.
    func characteristics(serviceUUID: CBUUID) -> CCBPublisher<[CCBCharacteristic]> {
        filter { $0.0.uuid == serviceUUID }.tryMap { service, error in
            guard let characteristics = service.characteristics, error == nil else {
                let service = CCBService(provider: service)
                throw CCBError.characteristicsDiscoveryFailed(service, error)
            }
            return characteristics.map(CCBCharacteristic.init)
        }
        .mapError(CCBError.init)
        .eraseToAnyPublisher()
    }
}

/// An extension that provides helper methods for publishers with an output
/// of `PeripheralDelegateWrapper.DidDiscoverServices`.
extension Publisher where Output == CCBPeripheralSubjects.DidDiscoverServices {

    /// Returns a publisher that maps the discovered services.
    /// - Parameter identifier: The identifier of the peripheral.
    func services(identifier: UUID) -> CCBPublisher<[CCBService]> {
        tryMap { services, error in
            guard let services = services, error == nil else {
                throw CCBError.servicesDiscoveryFailed(identifier, error)
            }
            return services.map(CCBService.init)
        }
        .mapError(CCBError.init)
        .eraseToAnyPublisher()
    }
}

/// An extension that provides helper methods for publishers with an output
/// of `PeripheralDelegateWrapper.DidUpdateValueForCharacteristic`.
extension Publisher where Output == CCBPeripheralSubjects.DidUpdateValueForCharacteristic {
    /// Returns a publisher that filters and maps the updated value for a characteristic.
    /// - Parameters:
    ///   - uuid: The UUID of the characteristic.
    ///   - mapError: A closure that takes a `CCBCharacteristic` and an `Error` and returns a `BluetoothError`.
    func characteristic(
        uuid: CBUUID,
        mapError: @escaping (CCBCharacteristic, Error?) -> CCBError
    ) -> CCBPublisher<CCBCharacteristic> {
        filter { $0.0.uuid == uuid }.tryMap { characteristic, error in
            let characteristic = CCBCharacteristic(provider: characteristic)
            guard error == nil else { throw mapError(characteristic, error) }
            return characteristic
        }
        .mapError(CCBError.init)
        .eraseToAnyPublisher()
    }
}
