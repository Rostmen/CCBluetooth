//
//  CCBService.swift
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

/// `CCBService` class encapsulates a service provided by a device.
public struct CCBService {
    /// The `CCBServiceProvider` instance that provides this service.
    let provider: CCBServiceProvider

    /// Initializes a new `CCBService` instance.
    /// - Parameter provider: The `CCBServiceProvider` that provides this service.
    init(provider: CCBServiceProvider) {
        self.provider = provider
    }

    /// The unique identifier for the service.
    public var uuid: CBUUID { provider.uuid }

    /// An array of the `CCBCharacteristic` instances that belong to the service.
    public var characteristics: [CCBCharacteristic]? {
        provider.characteristics?.map(CCBCharacteristic.init)
    }
}

/// Extends `CCBService` to conform to the `Equatable` protocol.
extension CCBService: Equatable {
    /// Determines whether two `CCBService` instances are equal.
    /// - Parameters:
    ///   - lhs: A `CCBService` instance.
    ///   - rhs: Another `CCBService` instance.
    /// - Returns: `true` if the two instances are equal, `false` otherwise.
    public static func == (lhs: CCBService, rhs: CCBService) -> Bool {
        lhs.uuid == rhs.uuid && lhs.characteristics == rhs.characteristics
    }
}
