//
//  CCBError.swift
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

import CoreBluetooth

/// `CCBError` is an enum that encapsulates all possible errors that can occur in the context of the `CCB` framework.
public enum CCBError: Error {
    /// Represents an unknown error. Includes the original `Error` for context.
    case unknown(Error)
    /// Represents a state where the entity was destroyed.
    case destroyed
    /// The device does not support Bluetooth.
    case bluetoothUnsupported
    /// The application is not authorized to use Bluetooth.
    case bluetoothUnauthorized
    /// The Bluetooth on the device is powered off.
    case bluetoothPoweredOff
    /// The Bluetooth on the device is in an unknown state.
    case bluetoothInUnknownState
    /// The Bluetooth on the device is resetting.
    case bluetoothResetting
    /// A scan operation is currently in progress.
    case scanInProgress
    /// A connection is already in progress with the peripheral.
    case peripheralIsAlreadyConnecting(UUID)
    /// The peripheral got disconnected.
    case peripheralDisconnected(UUID, Error?)
    /// Failed to connect to the peripheral.
    case peripheralFailedToConnect(UUID, Error?)
    /// Failed to discover services for a peripheral.
    case servicesDiscoveryFailed(UUID, Error?)
    /// Failed to discover characteristics for a service.
    case characteristicsDiscoveryFailed(CCBService, Error?)
    /// Failed to read a characteristic.
    case characteristicReadFailed(CCBCharacteristic, Error?)
    /// Failed to write to a characteristic.
    case characteristicWriteFailed(CCBCharacteristic, Error?)
    /// Write type is unknown.
    case unknownWriteType
}

/// `CCBError` extension for initializing `CCBError` from a generic `Error`.
extension CCBError {
    /// Initializes a new `CCBError` instance based on the given `Error`.
    /// - Parameter error: The `Error` that triggered the creation of a `CCBError`.
    init(error: Error) {
        guard let bluetoothError = error as? CCBError else {
            self = .unknown(error)
            return
        }
        self = bluetoothError
    }
}

/// `CCBError` extension for conforming to the `Equatable` protocol.
extension CCBError: Equatable {

    /// Determines whether two `CCBError` instances are equal.
    /// - Parameters:
    ///   - lhs: A `CCBError` instance.
    ///   - rhs: Another `CCBError` instance.
    /// - Returns: `true` if the two instances are equal, `false` otherwise.
    public static func == (lhs: CCBError, rhs: CCBError) -> Bool {
        switch (lhs, rhs) {
            case (.scanInProgress, .scanInProgress):
                return true
            case (.destroyed, .destroyed):
                return true
            case (.bluetoothUnsupported, .bluetoothUnsupported):
                return true
            case (.bluetoothUnauthorized, .bluetoothUnauthorized):
                return true
            case (.bluetoothPoweredOff, .bluetoothPoweredOff):
                return true
            case (.bluetoothInUnknownState, .bluetoothInUnknownState):
                return true
            case (.bluetoothResetting, .bluetoothResetting):
                return true
            case let (.servicesDiscoveryFailed(l, _), .servicesDiscoveryFailed(r, _)):
                return l == r
            case let (.peripheralIsAlreadyConnecting(l), .peripheralIsAlreadyConnecting(r)):
                return l == r
            case let (.peripheralFailedToConnect(l, _), .peripheralFailedToConnect(r, _)):
                return l == r
            case let (.peripheralDisconnected(l, _), .peripheralDisconnected(r, _)):
                return l == r
            case let (.characteristicsDiscoveryFailed(l, _), .characteristicsDiscoveryFailed(r, _)):
                return l == r
            case let (.characteristicReadFailed(l, _), .characteristicReadFailed(r, _)):
                return l == r
            case let (.unknown(l), .unknown(r)):
                return l.localizedDescription == r.localizedDescription
            default:
                return false
        }
    }


}
