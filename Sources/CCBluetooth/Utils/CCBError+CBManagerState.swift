//
//  CCBError+CBManagerState.swift
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

/// `CCBError` extension for mapping `CBManagerState` to corresponding `CCBError`.
extension CCBError {
    /// Initializes a new `CCBError` instance based on the given `CBManagerState`.
    /// - Parameter state: The current state of the `CBManager`.
    init?(state: CBManagerState) {
        switch state {
            case .poweredOff: self = .bluetoothPoweredOff
            case .resetting: self = .bluetoothResetting
            case .unauthorized: self = .bluetoothUnauthorized
            case .unknown: self = .bluetoothInUnknownState
            case .unsupported: self = .bluetoothUnsupported
            default: return nil
        }
    }
}
