//
//  Publisher+Amb.swift
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

    /// Creates a new `Publishers.Amb` publisher with the current and provided publisher.
    ///
    /// - Parameter other: Another publisher of the same output and failure type.
    ///
    /// - Returns: A `Publishers.Amb` instance combining the current and provided publishers.
    func amb<T: Publisher>(
        _ other: T
    ) -> Publishers.Amb<Self, T> where T.Output == Output, T.Failure == Failure {
        Publishers.Amb(left: self, right: other)
    }

    /// Creates a new `AnyPublisher` which will emit events from the first of current and provided publishers that emits an event.
    ///
    /// - Parameter others: One or more publishers of the same output and failure type.
    ///
    /// - Returns: A `AnyPublisher` instance combining the current and provided publishers.
    func amb<T: Publisher>(
        with others: T...
    ) -> AnyPublisher<Output, Failure> where T.Output == Output, T.Failure == Failure {
        amb(with: others)
    }

    /// Creates a new `AnyPublisher` which will emit events from the first of current and provided publishers that emits an event.
    ///
    /// - Parameter others: A collection of publishers of the same output and failure type.
    ///
    /// - Returns: A `AnyPublisher` instance combining the current and provided publishers.
    func amb<O: Collection>(with others: O) -> AnyPublisher<Output, Failure>
    where O.Element: Publisher, O.Element.Output == Output, O.Element.Failure == Failure {
        others.reduce(eraseToAnyPublisher()) { $0.amb($1).eraseToAnyPublisher() }
    }
}

extension Collection where Element: Publisher {

    /// Creates a new `AnyPublisher` which will emit events from the first publisher in the collection that emits an event.
    ///
    /// - Returns: A `AnyPublisher` instance combining the publishers in the collection.
    func amb() -> AnyPublisher<Element.Output, Element.Failure> {
        switch count {
            case 0: return Empty().eraseToAnyPublisher()
            case 1: return self[startIndex].amb(with: [Element]())
            default: return self[startIndex].amb(with: self[index(after: startIndex)...])
        }
    }
}

extension Publishers {

    /// A publisher that emits the events of the first of two publishers to emit an event.
    struct Amb<Left: Publisher, Right: Publisher>: Publisher where Left.Output == Right.Output,
                                                                   Left.Failure == Right.Failure {
        typealias Output = Left.Output
        typealias Failure = Left.Failure

        private let left: Left
        private let right: Right

        /// Creates a new `Amb` publisher.
        ///
        /// - Parameters:
        ///   - left: The first publisher.
        ///   - right: The second publisher.
        init(left: Left, right: Right) {
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

private extension Publishers.Amb {

    /// A subscription that propagates values from the first publisher that emits an event to a single downstream subscriber.
    class AmbSubscription<D: Subscriber>: Subscription
    where Output == D.Input, Failure == D.Failure {

        /// The left sink that manages demand and delivery from the first publisher.
        private var leftSink: AmbSink<Left, D>?

        /// The right sink that manages demand and delivery from the second publisher.
        private var rightSink: AmbSink<Right, D>?

        /// Stores the initial demand until a decision is made to select a publisher.
        private var preDecisionDemand = Subscribers.Demand.none

        /// The decision enum to decide which publisher to use for emitting values.
        private enum Decision {
            case left
            case right
        }

        /// The decision instance which will be set to either `.left` or `.right`.
        private var decision: Decision? {
            didSet {
                guard let decision = decision else { return }
                switch decision {
                    case .left: rightSink = nil
                    case .right: leftSink = nil
                }

                request(preDecisionDemand)
                preDecisionDemand = .none
            }
        }

        /// Initialize the `AmbSubscription` with two publishers and a downstream subscriber.
        ///
        /// - Parameters:
        ///   - left: The first publisher.
        ///   - right: The second publisher.
        ///   - downstream: The subscriber to attach to this publisher.
        init(left: Left, right: Right, downstream: D) {
            leftSink = .init(upstream: left, downstream: downstream) { [weak self] in
                self?.decision == .none ? self?.decision = .left : ()
            }
            rightSink = .init(upstream: right, downstream: downstream) { [weak self] in
                self?.decision == .none ? self?.decision = .right : ()
            }
        }

        /// Request a demand from either the left or the right sink depending on the decision.
        ///
        /// - Parameter demand: The number of elements requested by the subscriber.
        func request(_ demand: Subscribers.Demand) {
            guard decision != nil else {
                preDecisionDemand += demand
                return
            }

            leftSink?.demand(demand)
            rightSink?.demand(demand)
        }

        /// Cancel the subscription and nil out the sinks.
        func cancel() {
            leftSink?.cancelUpstream()
            leftSink = nil
            rightSink?.cancelUpstream()
            rightSink = nil
        }
    }
}

private extension Publishers.Amb {
    /// `AmbSink` is a helper class used within `Amb` to manage a single `Subscriber` for each `Publisher`.
    /// It forwards subscriptions, values and completions.
    class AmbSink<U: Publisher, D: Subscriber>: CCBSink<U, D>
    where U.Output == D.Input, U.Failure == D.Failure {

        /// The emitted closure is called whenever a value or a completion is received.
        private let emitted: () -> Void

        /// Creates a new instance of `AmbSink`.
        ///
        /// - Parameters:
        ///   - upstream: The `Publisher` to subscribe to.
        ///   - downstream: The `Subscriber` to forward events to.
        ///   - emitted: A closure to call whenever a value or a completion is received.
        init(upstream: U, downstream: D, emitted: @escaping () -> Void) {
            self.emitted = emitted
            super.init(upstream: upstream, downstream: downstream,
                       transformOutput: { $0 }, transformFailure: { $0 })
        }

        /// This method is called when the `Subscriber` has received a subscription from the `Publisher`.
        ///
        /// - Parameter subscription: The `Subscription` instance received from the `Publisher`.
        override func receive(subscription: Combine.Subscription) {
            super.receive(subscription: subscription)
            subscription.request(.max(1))
        }

        /// This method is called when a new event is received from the `Publisher`.
        ///
        /// - Parameter input: The value received from the `Publisher`.
        ///
        /// - Returns: The demand instance, requesting more or no further values.
        override func receive(_ input: U.Output) -> Subscribers.Demand {
            emitted()
            return buffer.buffer(value: input)
        }

        /// This method is called when the `Publisher` has completed, either due to an error or normally.
        ///
        /// - Parameter completion: A `Subscribers.Completion` case indicating how publishing completed.
        override func receive(completion: Subscribers.Completion<D.Failure>) {
            emitted()
            buffer.complete(completion: completion)
        }
    }

}
