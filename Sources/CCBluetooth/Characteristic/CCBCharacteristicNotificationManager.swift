//
//  CCBCharacteristicNotificationManager.swift
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

/// `CCBCharacteristicNotificationManager` manages the notifications related to characteristic's value updates.
class CCBCharacteristicNotificationManager {
    /// The peripheral the notifications are related to.
    private weak var peripheral: CCBPeripheralProvider?

    /// The dictionary holding the publishers for each characteristic.
    private var activePublishers: [CBUUID: CCBPublisher<CCBCharacteristic>] = [:]

    /// The dictionary tracking the number of subscribers for each characteristic.
    private var activePublishersCount: [CBUUID: Int] = [:]

    /// A lock to protect access to `activePublishers` and `activePublishersCount`.
    private let lock = NSLock()

    /// Initializes a new instance of `CharacteristicNotificationManager`.
    /// - Parameter peripheral: The peripheral the notifications are related to.
    init(peripheral: CCBPeripheralProvider) {
        self.peripheral = peripheral
    }

    /// Observes value updates and sets notifications for a characteristic.
    /// - Parameter characteristic: The characteristic to observe.
    /// - Returns: The publisher that emits the updated characteristic values.
    func observeValueUpdateAndSetNotification(
        for characteristic: CCBCharacteristic
    ) -> CCBPublisher<CCBCharacteristic> {
        Deferred { [weak self] () -> CCBPublisher<CCBCharacteristic> in
            guard let self = self, let subjects = self.peripheral?.subjects else {
                return .error(.destroyed)
            }

            self.lock.lock(); defer { self.lock.unlock() }

            if let activePublisher = self.activePublishers[characteristic.uuid] {
                return activePublisher
            }

            let publiser = self
                .createValueUpdatePublisher(for: characteristic, subjects: subjects)
                .handleEvents(receiveSubscription: { [weak self] _ in
                    self?.handleSubscribe(for: characteristic)
                }, receiveCompletion: { [weak self] _ in
                    self?.handleFinishSubscribtion(for: characteristic)
                }, receiveCancel: { [weak self] in
                    self?.handleFinishSubscribtion(for: characteristic)
                })
                .share()
                .eraseToAnyPublisher()

            self.activePublishers[characteristic.uuid] = publiser

            return publiser
        }
        .eraseToAnyPublisher()
    }

    /// Handles the subscription to a characteristic's value updates.
    /// - Parameter characteristic: The characteristic to subscribe.
    func handleSubscribe(for characteristic: CCBCharacteristic) {
        lock.lock(); defer { lock.unlock() }

        let counter = activePublishersCount[characteristic.uuid] ?? 0
        activePublishersCount[characteristic.uuid] = counter + 1
        setNotifyValue(true, for: characteristic)
    }

    /// Handles the unsubscription from a characteristic's value updates.
    /// - Parameter characteristic: The characteristic to unsubscribe.
    func handleFinishSubscribtion(for characteristic: CCBCharacteristic) {
        lock.lock(); defer { lock.unlock() }

        let counter = activePublishersCount[characteristic.uuid] ?? 1
        activePublishersCount[characteristic.uuid] = counter - 1

        guard counter <= 1 else { return }

        activePublishersCount.removeValue(forKey: characteristic.uuid)
        setNotifyValue(false, for: characteristic)
    }

    /// Creates a publisher for a characteristic's value updates.
    /// - Parameters:
    ///   - characteristic: The characteristic to observe.
    ///   - subjects: The delegate wrapper to forward delegate callbacks.
    /// - Returns: The publisher that emits the updated characteristic values.
    func createValueUpdatePublisher(
        for characteristic: CCBCharacteristic,
        subjects: CCBPeripheralSubjects
    ) -> CCBPublisher<CCBCharacteristic> {
        subjects
            .didUpdateValueForCharacteristicSubject
            .filter { $0.0.uuid == characteristic.uuid }
            .tryMap(tryMapCharacteristic)
            .mapError(CCBError.init)
            .eraseToAnyPublisher()
    }

    /// Tries to map a characteristic and its error to a new characteristic.
    /// - Parameters:
    ///   - characteristic: The original characteristic.
    ///   - error: The error related to the original characteristic.
    /// - Throws: `CCBError` if there is an error related to the original characteristic.
    /// - Returns: The new characteristic.
    private func tryMapCharacteristic(_ characteristic: CCBCharacteristicProvider,
                                      error: Error?) throws -> CCBCharacteristic {
        let characteristic = CCBCharacteristic(provider: characteristic)
        guard error == nil else {
            throw CCBError.characteristicReadFailed(characteristic, error)
        }
        return characteristic
    }

    /// Sets the notifying state for a characteristic.
    /// - Parameters:
    ///   - enabled: `true` to start notifying, `false` to stop.
    ///   - characteristic: The characteristic to update.
    func setNotifyValue(_ enabled: Bool, for characteristic: CCBCharacteristic) {
        guard let peripheral = peripheral, peripheral.state == .connected else { return }
        peripheral.setNotifyValue(enabled, for: characteristic.provider)
    }
}
