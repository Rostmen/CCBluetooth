//
//  CCBCentralManagerProvider.swift
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

/// A protocol that describes the functionality for managing and manipulating Bluetooth peripherals.
protocol CCBCentralManagerProvider: AnyObject {
    /// The subjects used for handling Bluetooth events.
    var subjects: CCBCentralManagerSubjects? { set get }

    /// The current state of the Bluetooth manager.
    var state: CBManagerState { get }

    /// A boolean indicating whether the Bluetooth manager is currently scanning for peripherals.
    var isScanning: Bool { get }

    /// Starts a scan for peripherals that offer services with the specified UUIDs.
    ///
    /// - Parameters:
    ///   - serviceUUIDs: An array of `CBUUID` objects representing the service UUIDs to scan for.
    ///   - options: An optional dictionary specifying options for the scan.
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)

    /// Stops an ongoing scan for peripherals.
    func stopScan()

    /// Connects to a specified peripheral.
    ///
    /// - Parameters:
    ///   - peripheral: The `CCBPeripheralProvider` to connect to.
    ///   - options: An optional dictionary specifying connection options.
    func connect(_ peripheral: CCBPeripheralProvider, options: [String : Any]?)

    /// Cancels an active or pending connection to a specified peripheral.
    ///
    /// - Parameter peripheral: The `CCBPeripheralProvider` to disconnect from.
    func cancelPeripheralConnection(_ peripheral: CCBPeripheralProvider)
}
