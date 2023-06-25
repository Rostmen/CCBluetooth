//
//  CCBCentralManagerSubjects.swift
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

/// `CCBCentralManagerSubjects` is a wrapper class that implements the `CBCentralManagerDelegate` protocol.
/// It uses `PassthroughSubject` instances to provide a Combine interface for the delegate methods.
class CCBCentralManagerSubjects: NSObject {

    /// Type alias for a function handling a state update from the central manager.
    typealias DidUpdateState = CCBCentralManagerProvider

    /// Type alias for a function handling the restoration of the state from the central manager.
    typealias WillRestoreState = (CCBCentralManagerProvider, [String : Any])

    /// Type alias for a function handling the discovery of a peripheral.
    typealias DidDiscover = (
        CCBCentralManagerProvider,
        CCBPeripheralProvider,
        [String : Any], NSNumber
    )

    /// Type alias for a function handling the successful connection to a peripheral.
    typealias DidConnect = (CCBCentralManagerProvider, CCBPeripheralProvider)

    /// Type alias for a function handling a failed connection attempt to a peripheral.
    typealias DidFailToConnect = (CCBCentralManagerProvider, CCBPeripheralProvider, Error?)

    /// Type alias for a function handling the disconnection from a peripheral.
    typealias DidDisconnectPeripheral = (CCBCentralManagerProvider, CCBPeripheralProvider, Error?)

    /// A publisher for state updates from the central manager.
    let didUpdateStateSubject = PassthroughSubject<DidUpdateState, Never>()

    /// A publisher for state restorations from the central manager.
    let willRestoreStateSubject = PassthroughSubject<WillRestoreState, Never>()

    /// A publisher for the discovery of peripherals.
    let didDiscoverSubject = PassthroughSubject<DidDiscover, Never>()

    /// A publisher for successful connections to peripherals.
    let didConnectSubject = PassthroughSubject<DidConnect, Never>()

    /// A publisher for failed connection attempts to peripherals.
    let didFailToConnectSubject = PassthroughSubject<DidFailToConnect, Never>()

    /// A publisher for disconnections from peripherals.
    let didDisconnectPeripheralSubject = PassthroughSubject<DidDisconnectPeripheral, Never>()

    /// Sends a completion event for each subject when the instance is deinitialized.
    deinit {
        didUpdateStateSubject.send(completion: .finished)
        willRestoreStateSubject.send(completion: .finished)
        didDiscoverSubject.send(completion: .finished)
        didConnectSubject.send(completion: .finished)
        didFailToConnectSubject.send(completion: .finished)
        didDisconnectPeripheralSubject.send(completion: .finished)
    }

    /// Updates the `didUpdateStateSubject` with the provided central manager.
    /// - Parameter central: The central manager whose state has been updated.
    func centralManagerDidUpdateState(central: CCBCentralManagerProvider) {
        didUpdateStateSubject.send(central)
    }

    /// Updates the `willRestoreStateSubject` with the provided central manager and restoration dictionary.
    /// - Parameters:
    ///   - central: The central manager whose state will be restored.
    ///   - dict: The dictionary containing restoration information.
    func centralManager(central: CCBCentralManagerProvider, willRestoreState dict: [String : Any]) {
        willRestoreStateSubject.send((central, dict))
    }

    /// Updates the `didDiscoverSubject` with the provided parameters.
    /// - Parameters:
    ///   - central: The central manager that discovered the peripheral.
    ///   - peripheral: The discovered peripheral.
    ///   - advertisementData: The advertisement data dictionary.
    ///   - RSSI: The signal strength of the peripheral.
    func centralManager(
        central: CCBCentralManagerProvider,
        didDiscover peripheral: CCBPeripheralProvider,
        advertisementData: [String : Any], rssi RSSI: NSNumber
    ) {
        didDiscoverSubject.send((central, peripheral, advertisementData, RSSI))
    }

    /// Updates the `didConnectSubject` with the provided central manager and peripheral.
    /// - Parameters:
    ///   - central: The central manager that connected to the peripheral.
    ///   - peripheral: The connected peripheral.
    func centralManager(
        central: CCBCentralManagerProvider,
        didConnect peripheral: CCBPeripheralProvider
    ) {
        didConnectSubject.send((central, peripheral))
    }

    /// Updates the `didFailToConnectSubject` with the provided parameters.
    /// - Parameters:
    ///   - central: The central manager that failed to connect.
    ///   - peripheral: The peripheral that failed to connect.
    ///   - error: The error, if any, that occurred during the connection.
    func centralManager(central: CCBCentralManagerProvider, didFailToConnect
                        peripheral: CCBPeripheralProvider, error: Error?) {
        didFailToConnectSubject.send((central, peripheral, error))
    }

    /// Updates the `didDisconnectPeripheralSubject` with the provided parameters.
    /// - Parameters:
    ///   - central: The central manager that disconnected from the peripheral.
    ///   - peripheral: The disconnected peripheral.
    ///   - error: The error, if any, that occurred during the disconnection.
    func centralManager(central: CCBCentralManagerProvider, didDisconnectPeripheral
                        peripheral: CCBPeripheralProvider, error: Error?) {
        didDisconnectPeripheralSubject.send((central, peripheral, error))
    }
}
