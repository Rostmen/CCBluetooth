//
//  CCBCharacteristic.swift
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

/// `CCBCharacteristic` class provides a generic implementation of `Characteristic`.
public class CCBCharacteristic {
    /// The provider that conforms to `CharacteristicType`.
    public let provider: CCBCharacteristicProvider

    /// Initializes a new instance of `CCBCharacteristic`.
    /// - Parameter provider: An object that conforms to `CCBCharacteristicProvider`.
    init(provider: CCBCharacteristicProvider) {
        self.provider = provider
    }

    /// The UUID for the characteristic.
    public var uuid: CBUUID { provider.uuid }

    /// A Boolean value that indicates whether the characteristic is currently notifying a subscribed central of its value.
    public var isNotifying: Bool { provider.isNotifying }

    /// The value of the characteristic.
    public var value: Data? { provider.value }

    /// The properties of the characteristic.
    public var properties: CBCharacteristicProperties { provider.properties }
}

/// `CCBCharacteristic` extension to conform to `Equatable`.
extension CCBCharacteristic: Equatable {
    /// Compares two `CCBCharacteristic` objects for equality.
    /// - Parameters:
    ///   - lhs: The left-hand side value to compare.
    ///   - rhs: The right-hand side value to compare.
    /// - Returns: `true` if the two values are equal, `false` otherwise.
    public static func == (lhs: CCBCharacteristic, rhs: CCBCharacteristic) -> Bool {
        lhs.uuid == rhs.uuid
    }
}
