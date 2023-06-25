//
//  CCBPeripheralSubjects.swift
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

/// Extension to make `CCBPeripheralSubjects` conform to `CBPeripheralDelegate`.
extension CCBPeripheralSubjects: CBPeripheralDelegate {

    /// Delegates the discovery of services to the wrapper function.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.peripheral(peripheral: peripheral, didDiscoverServices: error)
    }

    /// Delegates the discovery of characteristics for a service to the wrapper function.
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        self.peripheral(
            peripheral: peripheral,
            didDiscoverCharacteristicsFor: service,
            error: error
        )
    }

    /// Delegates the update of a characteristic's value to the wrapper function.
    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.peripheral(peripheral: peripheral, didUpdateValueFor: characteristic, error: error)
    }

    /// Delegates the writing of a characteristic's value to the wrapper function.
    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.peripheral(peripheral: peripheral, didWriteValueFor: characteristic, error: error)
    }

    /// Delegates the readiness of the peripheral to send write without a response to the wrapper function.
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        self.peripheralIsReadyToSendWriteWithoutResponse(peripheral)
    }
}
