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
import Combine

/// `CCBPeripheralSubjects` is a wrapper class for peripheral delegate callbacks.
public final class CCBPeripheralSubjects: NSObject {
    /// Represents a tuple that is used when services are discovered.
    /// - `services`: An array of discovered `CCBServiceProvider` instances.
    /// - `error`: An `Error` object if an error occurred while discovering services.
    typealias DidDiscoverServices = ([CCBServiceProvider]?, Error?)

    /// Represents a tuple used when characteristics for a service are discovered.
    /// - `service`: A `CCBServiceProvider` instance for which characteristics were discovered.
    /// - `error`: An `Error` object if an error occurred while discovering characteristics.
    typealias DidDiscoverCharacteristicsForService = (CCBServiceProvider, Error?)

    /// Represents a tuple used when a characteristic's value is updated.
    /// - `characteristic`: A `CCBCharacteristicProvider` instance whose value was updated.
    /// - `error`: An `Error` object if an error occurred while updating the characteristic's value.
    typealias DidUpdateValueForCharacteristic = (CCBCharacteristicProvider, Error?)

    /// Represents a tuple used when a characteristic's value has been written.
    /// - `characteristic`: A `CCBCharacteristicProvider` instance whose value was written.
    /// - `error`: An `Error` object if an error occurred while writing the characteristic's value.
    typealias DidWriteValueForCharacteristic = (CCBCharacteristicProvider, Error?)

    /// Represents a PassthroughSubject that broadcasts values to subscribers.
    /// - `T`: The type of elements being broadcast.
    typealias Subject<T> = PassthroughSubject<T, Never>

    /// Broadcasts when services are discovered.
    let didDiscoverServicesSubject = Subject<DidDiscoverServices>()

    /// Broadcasts when characteristics for a service are discovered.
    let didDiscoverCharacteristicsForServiceSubject =
    Subject<DidDiscoverCharacteristicsForService>()

    /// Broadcasts when a characteristic's value is updated.
    let didUpdateValueForCharacteristicSubject = Subject<DidUpdateValueForCharacteristic>()

    /// Broadcasts when a characteristic's value has been written.
    let peripheralDidWriteValueForCharacteristicSubject = Subject<DidWriteValueForCharacteristic>()

    /// Broadcasts when the peripheral is ready to send write without a response.
    let peripheralIsReadyToSendWriteWithoutResponseSubject = Subject<Void>()

    /// Cleans up the resources before the `CCBPeripheralSubjects` instance is deallocated.
    deinit {
        didDiscoverServicesSubject.send(completion: .finished)
        didDiscoverCharacteristicsForServiceSubject.send(completion: .finished)
        didUpdateValueForCharacteristicSubject.send(completion: .finished)
    }

    /// Sends a notification when services are discovered.
    /// - `peripheral`: The peripheral device where the services were discovered.
    /// - `error`: An optional error that might have occurred during the service discovery.
    func peripheral(peripheral: CCBPeripheralProvider, didDiscoverServices error: Error?) {
        didDiscoverServicesSubject.send((peripheral.services, error))
    }

    /// Sends a notification when characteristics for a service are discovered.
    /// - `peripheral`: The peripheral device where the characteristics were discovered.
    /// - `service`: The service for which the characteristics were discovered.
    /// - `error`: An optional error that might have occurred during the characteristic discovery.
    func peripheral(
        peripheral: CCBPeripheralProvider,
        didDiscoverCharacteristicsFor service: CCBServiceProvider,
        error: Error?
    ) {
        didDiscoverCharacteristicsForServiceSubject.send((service, error))
    }

    /// Sends a notification when a characteristic's value is updated.
    /// - `peripheral`: The peripheral device where the characteristic's value was updated.
    /// - `characteristic`: The characteristic whose value was updated.
    /// - `error`: An optional error that might have occurred during the value update.
    func peripheral(
        peripheral: CCBPeripheralProvider,
        didUpdateValueFor characteristic: CCBCharacteristicProvider,
        error: Error?
    ) {
        didUpdateValueForCharacteristicSubject.send((characteristic, error))
    }

    /// Sends a notification when a characteristic's value has been written.
    /// - `peripheral`: The peripheral device where the characteristic's value was written.
    /// - `characteristic`: The characteristic whose value was written.
    /// - `error`: An optional error that might have occurred during the write operation.
    func peripheral(
        peripheral: CCBPeripheralProvider,
        didWriteValueFor characteristic: CCBCharacteristicProvider,
        error: Error?
    ) {
        peripheralDidWriteValueForCharacteristicSubject.send((characteristic, error))
    }

    /// Sends a notification when the peripheral is ready to send write without a response.
    /// - `peripheral`: The peripheral device that is ready to send write without a response.
    public func peripheralIsReadyToSendWriteWithoutResponse(_ peripheral: CCBPeripheralProvider) {
        peripheralIsReadyToSendWriteWithoutResponseSubject.send()
    }
}
