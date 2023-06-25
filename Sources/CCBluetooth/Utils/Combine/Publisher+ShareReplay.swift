//
//  Publisher+ShareReplay.swift
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

/// Enum representing the scope for shared replay publishers.
enum ShareReplayScope {
    /// Retains emitted events indefinitely.
    case forever
    /// Retains emitted events only while there are active subscribers.
    case whileConnected
}

extension Publishers {

    /// A publisher that shares and replays events to its subscribers according to the defined `ShareReplayScope`.
    final class ShareReplayScopePublisher<U: Publisher>: Publisher {

        /// The type of values that the publisher emits.
        typealias Output = U.Output

        /// The type of errors that the publisher might publish.
        typealias Failure = U.Failure

        /// Recursive lock for protecting access to `replay`, `subscriptions`, and `completion`.
        private let lock = NSRecursiveLock()

        /// The upstream publisher from where the values and completion events will be received.
        private let upstream: U

        /// The maximum number of values to store and replay to new subscribers.
        private let capacity: Int

        /// The scope defines how and when the replayed values should be cleared.
        private let scope: ShareReplayScope

        /// The array to store the most recently published values.
        private var replay = [Output]()

        /// An array to store all active subscriptions.
        private var subscriptions = [ShareReplaySubscription<Output, Failure>]()

        /// Holds the completion event if it has already occurred.
        private var completion: Subscribers.Completion<Failure>? = nil
        
        /// Initializer for ShareReplayScopePublisher.
        ///
        /// - Parameters:
        ///   - upstream: The upstream publisher.
        ///   - capacity: The maximum number of values to store and replay to new subscribers.
        ///   - scope: The scope in which elements should be replayed.
        init(upstream: U, capacity: Int, scope: ShareReplayScope) {
            self.upstream = upstream
            self.capacity = capacity
            self.scope = scope
        }
        
        /// Appends the received value to the `replay` array and emits it to all subscribers.
        ///
        /// - Parameter value: The newly received value.
        private func relay(_ value: Output) {
            lock.lock(); defer { lock.unlock() }
            switch scope {
                case .forever where completion != nil:
                    return
                default:
                    replay.append(value)
                    if replay.count > capacity {
                        replay.removeFirst()
                    }
            }
            
            subscriptions.forEach { $0.receive(value) }
        }
        
        /// Emits the completion event to all subscribers and clears the `replay` array and `subscriptions` array based
        /// on the `scope`.
        ///
        /// - Parameter completion: The completion event.
        private func complete(_ completion: Subscribers.Completion<Failure>) {
            lock.lock(); defer { lock.unlock() }
            subscriptions.forEach { $0.receive(completion: completion) }
            switch scope {
                case .whileConnected:
                    replay.removeAll()
                    subscriptions.removeAll()
                case .forever:
                    self.completion = completion
            }
        }
        
        /// Accepts a new subscriber and starts a subscription process.
        ///
        /// - Parameter subscriber: The subscriber that is subscribing to the publisher.
        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            lock.lock(); defer { lock.unlock() }

            let subscription = ShareReplaySubscription(
                subscriber: subscriber,
                replay: replay,
                capacity: capacity,
                completion: completion
            )
            
            subscriptions.append(subscription)
            subscriber.receive(subscription: subscription)
            
            guard subscriptions.count == 1 else { return }
            let sink = AnySubscriber(receiveSubscription: { subscription in
                subscription.request(.unlimited)
            }, receiveValue: { [weak self] (value: Output) -> Subscribers.Demand in
                self?.relay(value)
                return .none
            }, receiveCompletion: { [weak self] in
                self?.complete($0)
            })
            
            upstream.subscribe(sink)
        }
    }
}

/// `ShareReplaySubscription` acts as an intermediary between the `Publisher` and `Subscriber`.
fileprivate class ShareReplaySubscription<Output, Failure>: Subscription where Failure: Error {

    /// Maximum capacity for the buffer.
    private let capacity: Int

    /// The subscriber that is receiving values.
    private var subscriber: AnySubscriber<Output, Failure>? = nil

    /// The number of items that the subscriber wants to receive.
    private var demand: Subscribers.Demand = .none

    /// Buffer for storing published values.
    private var buffer: [Output]

    /// Completion event.
    private var completion: Subscribers.Completion<Failure>? = nil

    /// Flag to check if the subscription is completed.
    private var isCompleted = false
    
    /// Initializes a new instance of a share replay subscription.
    ///
    /// - Parameters:
    ///   - subscriber: The subscriber that will receive the values.
    ///   - replay: Buffer of values to be replayed.
    ///   - capacity: Maximum capacity for the buffer.
    ///   - completion: The completion event.
    init<S: Subscriber>(
        subscriber: S,
        replay: [Output],
        capacity: Int,
        completion: Subscribers.Completion<Failure>?
    ) where Failure == S.Failure, Output == S.Input {
        self.subscriber = AnySubscriber(subscriber)
        self.buffer = replay
        self.capacity = capacity
        self.completion = completion
    }
    
    /// Completes the subscription with the provided completion event.
    ///
    /// - Parameter completion: The completion event.
    private func complete(with completion: Subscribers.Completion<Failure>) {
        guard let subscriber = subscriber else { return }
        self.subscriber = nil
        self.completion = nil
        self.buffer.removeAll()
        subscriber.receive(completion: completion)
    }
    
    /// Sends as many values as the demand requires.
    private func emitAsNeeded() {
        guard let subscriber = subscriber else { return }
        while self.demand > .none && !buffer.isEmpty {
            self.demand -= .max(1)
            let nextDemand = subscriber.receive(buffer.removeFirst())
            if nextDemand != .none {
                self.demand += nextDemand
            }
        }
        if let completion = completion {
            complete(with: completion)
        }
    }
    
    /// Requests the specified number of items.
    ///
    /// - Parameter demand: The number of items to request.
    func request(_ demand: Subscribers.Demand) {
        if demand != .none {
            self.demand += demand
        }
        emitAsNeeded()
    }
    
    /// Cancels the subscription.
    func cancel() {
        isCompleted = true
    }
    
    /// Sends the specified input to the subscriber.
    ///
    /// - Parameter input: The input to send.
    func receive(_ input: Output) {
        guard subscriber != nil else { return }
        buffer.append(input)
        if buffer.count > capacity {
            buffer.removeFirst()
        }
        emitAsNeeded()
    }
    
    /// Sends the completion event to the subscriber.
    ///
    /// - Parameter completion: The completion event.
    func receive(completion: Subscribers.Completion<Failure>) {
        guard !isCompleted else { return }
        isCompleted = true
        guard let subscriber = subscriber else { return }
        self.subscriber = nil
        self.buffer.removeAll()
        subscriber.receive(completion: completion)
    }
}

extension Publisher {

    /// Returns a publisher that replays elements according to the specified scope and capacity.
    ///
    /// - Parameters:
    ///   - capacity: The maximum number of elements to store for replaying to future subscribers.
    ///   - scope: The scope in which elements should be replayed.
    /// - Returns: A publisher that shares a replay of up to `capacity` elements published by the upstream publisher.
    func shareReplay(
        _ capacity: Int = .max, scope: ShareReplayScope = .forever
    ) -> Publishers.ShareReplayScopePublisher<Self> {
        Publishers.ShareReplayScopePublisher(upstream: self, capacity: capacity, scope: scope)
    }
}
