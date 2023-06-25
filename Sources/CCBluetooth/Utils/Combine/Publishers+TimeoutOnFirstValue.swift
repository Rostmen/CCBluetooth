//
//  Publishers+TimeoutOnFirstValue.swift
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

extension Publishers {

    /// A publisher that emits an error if the first value is not received before a timeout.
    struct TimeoutOnFirstValue<P: Publisher>: Publisher {
        typealias Output = P.Output
        typealias Failure = P.Failure

        /// The upstream publisher from which this publisher receives elements.
        let publisher: P

        /// The timeout interval within which the first value should be received.
        let time: Double

        /// A closure that provides the error to send if the first value is not received in time.
        let failure: () -> Failure

        /// Prepares to receive the `Subscriber` and begins sending values.
        ///
        /// - Parameter subscriber: The subscriber that will receive values and completion.
        func receive<S>(
            subscriber: S
        ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subj = PassthroughSubject<Output, Failure>()
            let task = DispatchWorkItem { subj.send(completion: .failure(failure())) }

            Merge(
                publisher.handleEvents(
                    receiveSubscription: {_ in
                        DispatchQueue
                            .global(qos: .background)
                            .asyncAfter(deadline: DispatchTime.now() + time, execute: task)
                    },
                    receiveOutput: { _ in task.cancel() },
                    receiveCompletion: { _ in task.cancel() },
                    receiveCancel: { task.cancel() }
                ),
                subj
            )
            .subscribe(subscriber)
        }
    }
}

extension Publisher {

    /// Attaches a timeout to the first value received from the publisher.
    ///
    /// - Parameters:
    ///   - time: The timeout interval within which the first value should be received.
    ///   - failure: A closure that provides the error to send if the first value is not received in time.
    /// - Returns: A `TimeoutOnFirstValue` publisher that signals an error if the first value is not received before the timeout.
    func timeoutOnFirstValue(
        time: Double,
        failure: @escaping () -> Failure
    ) -> Publishers.TimeoutOnFirstValue<Self> {
        Publishers.TimeoutOnFirstValue(publisher: self, time: time, failure: failure)
    }
}
