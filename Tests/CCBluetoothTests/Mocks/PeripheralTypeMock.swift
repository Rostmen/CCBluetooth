//
//  PeripheralTypeMock.swift
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

import Foundation
import CoreBluetooth
@testable import CCBluetooth

final class PeripheralTypeMock: CCBPeripheralProvider {
    var services: [CBService]?

    weak var subjects: CCBPeripheralSubjects?

    var canSendWriteWithoutResponse: Bool = true

    var identifier: UUID = UUID()

    var name: String? = "test"

    var rssi: NSNumber? = 1

    var state: CBPeripheralState = .disconnected
    
    var isNotifiedEnabledForCharacteristic: [CBUUID: Bool] = [:]

    func discoverServices(
        _ serviceUUIDs: [CBUUID]?
    ) {

    }

    func discoverCharacteristics(
        _ characteristicUUIDs: [CBUUID]?,
        for service: CCBServiceProvider
    ) {

    }

    func readValue(
        for characteristic: CCBCharacteristicProvider
    ) {

    }

    func maximumWriteValueLength(
        for type: CBCharacteristicWriteType
    ) -> Int {
        return 0
    }

    func writeValue(
        _ data: Data,
        for characteristic: CCBCharacteristicProvider,
        type: CBCharacteristicWriteType
    ) {

    }

    func observeValueUpdateAndSetNotification(
        for characteristic: CCBCharacteristicProvider
    ) {

    }

    func setNotifyValue(
        _ enabled: Bool,
        for characteristic: CCBCharacteristicProvider
    ) {
        isNotifiedEnabledForCharacteristic[characteristic.uuid] = enabled
    }

}
