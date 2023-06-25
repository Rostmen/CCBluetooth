//
//  Publisher+Absorb.swift
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

extension Publisher {

    /// Creates a new `Publishers.Absorb` publisher using the current and provided publisher.
    ///
    /// - Parameter other: Another publisher of the same output and failure type.
    ///
    /// - Returns: A `Publishers.Absorb` instance combining the current and provided publishers.
    func absorb<Other: Publisher>(_ other: Other) -> Publishers.Absorb<Other, Self> {
        Publishers.Absorb(left: other, right: self)
    }
}

extension Publishers {

    /// A publisher that absorbs the emissions of two publishers of the same type.
    ///
    /// The `Absorb` publisher forwards all events from both publishers to its downstream subscribers.
    struct Absorb<T: Publisher, U: Publisher>: Publisher
    where T.Output == U.Output, T.Failure == U.Failure {

        typealias Output = T.Output
        typealias Failure = T.Failure

        private let left: T
        private let right: U

        /// Creates a new `Absorb` publisher.
        ///
        /// - Parameters:
        ///   - left: The left publisher.
        ///   - right: The right publisher.
        init(left: T, right: U) {
            self.left = left
            self.right = right
        }

        /// Attaches the specified subscriber to this publisher.
        ///
        /// - Parameter subscriber: The subscriber to attach to this publisher.
        func receive<S: Subscriber>(
            subscriber: S
        ) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(
                subscription: AmbSubscription(left: left, right: right, downstream: subscriber)
            )
        }
    }
}

private extension Publishers.Absorb {
    /// A subscription that propagates values from two publishers to a single downstream subscriber.
    class AmbSubscription<D: Subscriber>: Subscription
    where Output == D.Input, Failure == D.Failure {

        private var leftSink: CCBSink<T, D>?
        private var rightSink: CCBSink<U, D>?

        /// Creates a new `Subscription` that merges two upstream publishers.
        ///
        /// - Parameters:
        ///   - left: The left publisher.
        ///   - right: The right publisher.
        ///   - downstream: The subscriber to receive events.
        init(left: T, right: U, downstream: D) {
            leftSink = CCBSink(upstream: left, downstream: downstream,
                               transformOutput: { $0 }, transformFailure: { $0 })

            rightSink = CCBSink(upstream: right, downstream: downstream,
                                transformOutput: { $0 }, transformFailure: { $0 })
        }

        /// Signals this subscription to request demand from its upstream publishers.
        ///
        /// - Parameter demand: The requested number of values to deliver.
        func request(_ demand: Subscribers.Demand) {
            leftSink?.demand(demand)
            rightSink?.demand(demand)
        }

        /// Signals this subscription to cancel and stop receiving events.
        func cancel() {
            leftSink = nil
            rightSink = nil
        }
    }
}
