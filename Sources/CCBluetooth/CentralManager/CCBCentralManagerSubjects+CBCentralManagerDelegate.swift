//
//  CCBCentralManagerSubjects+CBCentralManagerDelegate.swift
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
import CoreBluetooth

/// Conforms `CentralManagerDelegateWrapper` to `CBCentralManagerDelegate`.
extension CCBCentralManagerSubjects: CBCentralManagerDelegate {

    /// Updates the `didUpdateStateSubject` with the provided central manager.
    /// - Parameter central: The central manager whose state has been updated.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerDidUpdateState(central: central)
    }

    /// Updates the `willRestoreStateSubject` with the provided central manager and restoration dictionary.
    /// - Parameters:
    ///   - central: The central manager whose state will be restored.
    ///   - dict: The dictionary containing restoration information.
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        centralManager(central: central, willRestoreState: dict)
    }

    /// Updates the `didDiscoverSubject` with the provided parameters.
    /// - Parameters:
    ///   - central: The central manager that discovered the peripheral.
    ///   - peripheral: The discovered peripheral.
    ///   - advertisementData: The advertisement data dictionary.
    ///   - RSSI: The signal strength of the peripheral.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        centralManager(central: central, didDiscover: peripheral,
                       advertisementData: advertisementData, rssi: RSSI)
    }

    /// Updates the `didConnectSubject` with the provided central manager and peripheral.
    /// - Parameters:
    ///   - central: The central manager that connected to the peripheral.
    ///   - peripheral: The connected peripheral.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager(central: central, didConnect: peripheral)
    }

    /// Updates the `didFailToConnectSubject` with the provided parameters.
    /// - Parameters:
    ///   - central: The central manager that failed to connect.
    ///   - peripheral: The peripheral that failed to connect.
    ///   - error: The error, if any, that occurred during the connection.
    func centralManager(_ central: CBCentralManager, didFailToConnect
                        peripheral: CBPeripheral, error: Error?) {
        centralManager(central: central, didFailToConnect: peripheral, error: error )
    }

    /// Updates the `didDisconnectPeripheralSubject` with the provided parameters.
    /// - Parameters:
    ///   - central: The central manager that disconnected from the peripheral.
    ///   - peripheral: The disconnected peripheral.
    ///   - error: The error, if any, that occurred during the disconnection.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral
                        peripheral: CBPeripheral, error: Error?) {
        centralManager(central: central, didDisconnectPeripheral: peripheral, error: error)
    }
}

