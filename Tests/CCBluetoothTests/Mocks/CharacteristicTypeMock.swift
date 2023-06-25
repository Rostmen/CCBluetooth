//
//  CharacteristicTypeMock.swift
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

final class CharacteristicTypeMock: CCBCharacteristicProvider {
    var uuid: CBUUID = CBUUID()

    var isNotifying: Bool = false
    var mockValue: Data?
    var value: Data? {
        mockValue
    }
    var properties: CBCharacteristicProperties = .read
    
}
