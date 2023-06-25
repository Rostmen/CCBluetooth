//
//  CCBScanResult.swift
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

/// A struct representing the result of a Bluetooth scan.
public struct CCBScanResult {
    /// The peripheral device found during the scan.
    public let peripheral: CCBPeripheral

    /// Data advertised by the peripheral.
    public let advertisementData: CCBAdvertisementData

    /// Signal strength of the peripheral at the time of the scan.
    public let rssi: NSNumber
}

/// Conformance to `Equatable`.
extension CCBScanResult: Equatable {}
