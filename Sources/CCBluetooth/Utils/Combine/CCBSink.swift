//
//  CCBSink.swift
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

/// `CCBSink` subscribes to an upstream publisher and passes its output to a downstream subscriber.
class CCBSink<U: Publisher, D: Subscriber>: Subscriber {

    /// A closure that transforms the upstream publisher's failure into the downstream subscriber's failure.
    /// - Parameter failure: The failure from the upstream publisher.
    /// - Returns: The transformed failure for the downstream subscriber, or `nil` if the failure can't be transformed.
    typealias TransformFailure = (U.Failure) -> D.Failure?

    /// A closure that transforms the upstream publisher's output into the downstream subscriber's input.
    /// - Parameter output: The output from the upstream publisher.
    /// - Returns: The transformed output for the downstream subscriber, or `nil` if the output can't be transformed.
    typealias TransformOutput = (U.Output) -> D.Input?

    /// A buffer for handling demand between `Subscriber` and `Publisher`.
    private(set) var buffer: CCBDemandBuffer<D>

    /// A reference to the `Subscription` for the upstream `Publisher`.
    private var upstreamSubscription: Subscription?

    /// An optional transformation function to convert upstream output to downstream input.
    private let transformOutput: TransformOutput?

    /// An optional transformation function to convert upstream failures to downstream failures.
    private let transformFailure: TransformFailure?

    /// Initialize a new sink subscribing to the upstream publisher and
    /// fulfilling the demand of the downstream subscriber using a backpresurre
    /// demand-maintaining buffer.
    ///
    /// - Parameters:
    ///  - upstream: The upstream publisher
    ///  - downstream: The downstream subscriber
    ///  - transformOutput: Transform the upstream publisher's output type to the downstream's input type
    ///  - transformFailure: Transform the upstream failure type to the downstream's failure type
    ///
    /// - Note: You **must** provide the two transformation functions above if you're using
    ///         the default `Sink` implementation. Otherwise, you must subclass `Sink` with your own
    ///         publisher's sink and manage the buffer accordingly.
    init(
        upstream: U,
        downstream: D,
        transformOutput: TransformOutput? = nil,
        transformFailure: TransformFailure? = nil
    ) {
        self.buffer = CCBDemandBuffer(subscriber: downstream)
        self.transformOutput = transformOutput
        self.transformFailure = transformFailure
        upstream.subscribe(self)
    }

    /// Requests more data from the upstream publisher, according to the incoming demand.
    ///
    /// - Parameter demand: The number of elements requested by the downstream.
    func demand(_ demand: Subscribers.Demand) {
        let newDemand = buffer.demand(demand)
        upstreamSubscription?.requestIfNeeded(newDemand)
    }

    /// Establishes a subscription with the upstream publisher.
    ///
    /// - Parameter subscription: The subscription that the upstream publisher offers.
    func receive(subscription: Subscription) {
        upstreamSubscription = subscription
    }

    /// Receives new values from the upstream publisher and passes them downstream.
    ///
    /// - Parameter input: The new element from the upstream publisher.
    /// - Returns: The demand for more elements.
    func receive(_ input: U.Output) -> Subscribers.Demand {
        guard let transform = transformOutput else {
            fatalError("Missing output transformation")
        }

        guard let input = transform(input) else { return .none }
        return buffer.buffer(value: input)
    }

    /// Receives the completion event from the upstream publisher.
    ///
    /// - Parameter completion: A `Subscribers.Completion` instance which indicates whether the publisher finished
    /// normally or with an error.
    func receive(completion: Subscribers.Completion<U.Failure>) {
        switch completion {
            case .finished:
                buffer.complete(completion: .finished)
            case .failure(let error):
                guard let transform = transformFailure else {
                    fatalError("Missing failure transformation")
                }

                guard let error = transform(error) else { return }
                buffer.complete(completion: .failure(error))
        }

        cancelUpstream()
    }

    /// Cancels the subscription to the upstream publisher.
    func cancelUpstream() {
        upstreamSubscription.kill()
    }

    deinit { cancelUpstream() }
}
