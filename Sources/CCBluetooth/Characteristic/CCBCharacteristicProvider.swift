//
//  CCBCharacteristicProvider.swift
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

/// `CCBCharacteristicProvider` protocol defines the required properties for any type representing a BLE characteristic.
public protocol CCBCharacteristicProvider {
    /// The UUID for the characteristic.
    var uuid: CBUUID { get }

    /// A Boolean value that indicates whether the characteristic is currently notifying a subscribed central of its value.
    var isNotifying: Bool { get }

    /// The value of the characteristic.
    var value: Data? { get }

    /// The properties of the characteristic.
    var properties: CBCharacteristicProperties { get }
}
