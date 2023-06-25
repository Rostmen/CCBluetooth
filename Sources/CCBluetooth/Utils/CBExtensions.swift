//
//  CBExtensions.swift
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

/// This extension provides `CBCharacteristic` conformance to the `CCBCharacteristicProvider` protocol.
extension CBCharacteristic: CCBCharacteristicProvider {}

/// This extension provides `CBService` conformance to the `CCBServiceProvider` protocol.
extension CBService: CCBServiceProvider {}

/// This extension provides `CBPeripheral` conformance to the `CCBPeripheralProvider` protocol,
/// as well as adding custom behavior.
extension CBPeripheral: CCBPeripheralProvider {
    /// `CCBPeripheralSubjects` associated with the `CBPeripheral`. It gets or sets the delegate
    /// of the `CBPeripheral` instance.
    public var subjects: CCBPeripheralSubjects? {
        get { delegate as? CCBPeripheralSubjects }
        set { delegate = newValue}
    }

    /// Sets the `CCBCharacteristicProvider` for observing value updates and notification setting.
    /// - Parameter characteristic: The characteristic to observe for value updates.
    public func observeValueUpdateAndSetNotification(
        for characteristic: CCBCharacteristicProvider
    ) {

    }

    /// Discovers services with given UUIDs for a peripheral.
    /// - Parameters:
    ///   - characteristicUUIDs: The UUIDs of the services to discover.
    ///   - service: The service provider.
    public func discoverCharacteristics(
        _ characteristicUUIDs: [CBUUID]?,
        for service: CCBServiceProvider
    ) {
        guard let service = service as? CBService else { return }
        discoverCharacteristics(characteristicUUIDs, for: service)
    }

    /// Reads the value for a given characteristic.
    /// - Parameter characteristic: The characteristic to read the value from.
    public func readValue(for characteristic: CCBCharacteristicProvider) {
        guard let characteristic = characteristic as? CBCharacteristic else {
            return
        }
        readValue(for: characteristic)
    }

    /// Writes a value to a given characteristic.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - characteristic: The characteristic to write to.
    ///   - type: The type of write operation.
    public func writeValue(
        _ data: Data,
        for characteristic: CCBCharacteristicProvider,
        type: CBCharacteristicWriteType
    ) {
        guard let characteristic = characteristic as? CBCharacteristic else {
            return
        }
        writeValue(data, for: characteristic, type: type)
    }

    /// Sets whether to notify the observer about changes to the characteristic's value.
    /// - Parameters:
    ///   - enabled: A Boolean that indicates whether to notify the observer.
    ///   - characteristic: The characteristic to observe.
    public func setNotifyValue(_ enabled: Bool, for characteristic: CCBCharacteristicProvider) {
        guard let characteristic = characteristic as? CBCharacteristic else {
            return
        }
        setNotifyValue(enabled, for: characteristic)
    }
}

/// This extension provides `CBCentralManager` conformance to the `CCBCentralManagerProvider` protocol,
/// as well as adding custom behavior.
extension CBCentralManager: CCBCentralManagerProvider {

    /// `CCBCentralManagerSubjects` associated with the `CBCentralManager`.
    /// It gets or sets the delegate of the `CBCentralManager` instance.
    var subjects: CCBCentralManagerSubjects? {
        get { delegate as? CCBCentralManagerSubjects }
        set { delegate = newValue }
    }

    /// Connects to the specified peripheral.
    /// - Parameters:
    ///   - peripheral: The peripheral to connect to.
    ///   - options: An optional dictionary specifying connection behavior options.
    public func connect(_ peripheral: CCBPeripheralProvider, options: [String : Any]?) {
        guard let peripheral = peripheral as? CBPeripheral else { return }
        connect(peripheral, options: options)
    }

    /// Cancels a pending connection to a peripheral.
    /// - Parameter peripheral: The peripheral for which to cancel the connection.
    public func cancelPeripheralConnection(_ peripheral: CCBPeripheralProvider) {
        guard let peripheral = peripheral as? CBPeripheral else { return }
        cancelPeripheralConnection(peripheral)
    }
}
