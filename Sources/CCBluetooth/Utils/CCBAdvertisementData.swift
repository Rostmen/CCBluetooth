//
//  CCBAdvertisementData.swift
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

/// This structure encapsulates the data a peripheral advertises.
public struct CCBAdvertisementData {

    // The advertisement data dictionary from the peripheral
    public let advertisementData: [String: Any]

    // Initialize the struct with a given dictionary
    public init(_ advertisementData: [String: Any]) {
        self.advertisementData = advertisementData
    }

    // Local name advertised by the peripheral
    public var localName: String? {
        advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }

    // Manufacturer data advertised by the peripheral
    public var manufacturerData: Data? {
        advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }

    // Service data advertised by the peripheral
    public var serviceData: [CBUUID: Data]? {
        advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
    }

    // UUIDs of the services advertised by the peripheral
    public var serviceUUIDs: [CBUUID]? {
        advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }

    // UUIDs of the overflow services advertised by the peripheral
    public var overflowServiceUUIDs: [CBUUID]? {
        advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }

    // Transmission power level of the peripheral
    public var txPowerLevel: NSNumber? {
        advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
    }

    // Whether the peripheral is connectable
    public var isConnectable: Bool? {
        advertisementData[CBAdvertisementDataIsConnectable] as? Bool
    }

    // UUIDs of the services solicited by the peripheral
    public var solicitedServiceUUIDs: [CBUUID]? {
        advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
}

extension CCBAdvertisementData: Equatable {

    /// This operator overloading allows two instances of `CCBAdvertisementData` to be compared for equality.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `CCBAdvertisementData` instance to be compared.
    ///   - rhs: The right-hand side `CCBAdvertisementData` instance to be compared.
    ///
    /// - Returns: A Boolean value indicating whether the two instances are equal. Two instances are considered equal if their
    /// `localName`, `manufacturerData`, `serviceData`, `serviceUUIDs`,
    /// `overflowServiceUUIDs`, `txPowerLevel`, `isConnectable`, and `solicitedServiceUUIDs`
    /// properties are all equal.
    public static func == (lhs: CCBAdvertisementData, rhs: CCBAdvertisementData) -> Bool {
        lhs.localName == rhs.localName &&
        lhs.manufacturerData == rhs.manufacturerData &&
        lhs.serviceData == rhs.serviceData &&
        lhs.serviceUUIDs == rhs.serviceUUIDs &&
        lhs.overflowServiceUUIDs == rhs.overflowServiceUUIDs &&
        lhs.txPowerLevel == rhs.txPowerLevel &&
        lhs.isConnectable == rhs.isConnectable &&
        lhs.solicitedServiceUUIDs == rhs.solicitedServiceUUIDs
    }
}
