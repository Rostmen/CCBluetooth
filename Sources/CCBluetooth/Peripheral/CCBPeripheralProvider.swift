//
//  CCBPeripheralProvider.swift
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

/// `CCBPeripheralProvider` defines a set of functionalities that a peripheral in the Core Bluetooth framework needs to provide.
public protocol CCBPeripheralProvider: AnyObject {

    /// The subjects that the peripheral object calls when peripheral-specific events occur.
    var subjects: CCBPeripheralSubjects? { set get }

    /// The unique identifier (UUID) of the peripheral.
    var identifier: UUID { get }

    /// The local name of the peripheral.
    var name: String? { get }

    /// The current received signal strength indicator (RSSI) of the peripheral, in decibels.
    var rssi: NSNumber? { get }

    /// The current connection state of the peripheral.
    var state: CBPeripheralState { get }

    /// The services discovered on the peripheral.
    var services: [CBService]? { get }

    /// A Boolean value that indicates whether the peripheral has space available to perform more write without response operations.
    var canSendWriteWithoutResponse: Bool { get }

    /// Discovers the services of the peripheral.
    /// - Parameter serviceUUIDs: An array of `CBUUID` objects that you are interested in.
    /// Here, each `CBUUID` object represents a service UUID.
    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    /// Discovers the specified characteristics of a service.
    /// - Parameters:
    ///   - characteristicUUIDs: An array of `CBUUID` objects that you are interested in.
    ///   Here, each `CBUUID` object represents a characteristic UUID.
    ///   - service: The `CCBServiceProvider` that specifies the service of the characteristics.
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CCBServiceProvider)

    /// Reads the value of a specified characteristic.
    /// - Parameter characteristic: The `CCBCharacteristicProvider` that specifies the characteristic.
    func readValue(for characteristic: CCBCharacteristicProvider)

    /// Writes the value of a characteristic.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - characteristic: The `CCBCharacteristicProvider` that specifies the characteristic.
    ///   - type: The write type for the characteristic.
    func writeValue(
        _ data: Data,
        for characteristic: CCBCharacteristicProvider,
        type: CBCharacteristicWriteType
    )

    /// Sets up notifications or indications for the value of a specified characteristic.
    /// - Parameter characteristic: The `CCBCharacteristicProvider` that specifies the characteristic.
    func observeValueUpdateAndSetNotification(for characteristic: CCBCharacteristicProvider)

    /// Sets notifications or indications for the value of a specified characteristic.
    /// - Parameters:
    ///   - enabled: The option to enable or disable notifications/indications.
    ///   - characteristic: The `CCBCharacteristicProvider` that specifies the characteristic.
    func setNotifyValue(_ enabled: Bool, for characteristic: CCBCharacteristicProvider)
}
