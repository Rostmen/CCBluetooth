//
//  Publisher+Materialize.swift
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

import Combine

/// An enumeration that can represent a value (`Output`), a failure (`Failure`), or a completion event.
enum Event<Output, Failure: Swift.Error> {
    
    /// Represents a value emitted by the publisher.
    case value(Output)
    /// Represents a failure event with an error.
    case failure(Failure)
    /// Represents a finished event indicating the completion of publisher's emission.
    case finished
}

extension Event: Equatable where Output: Equatable, Failure: Equatable {
    
    /// An Equatable conformance for Event, allowing for comparisons.
    /// - Parameters:
    ///   - lhs: The left hand side Event.
    ///   - rhs: The right hand side Event.
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.finished, .finished):
                return true
            case let (.failure(err1), .failure(err2)):
                return err1 == err2
            case let (.value(val1), .value(val2)):
                return val1 == val2
            default:
                return false
        }
    }
}

extension Event: CustomStringConvertible {
    
    /// Provides a string description of the Event.
    var description: String {
        switch self {
            case .value(let val):
                return "value(\(val))"
            case .failure(let err):
                return "failure(\(err))"
            case .finished:
                return "finished"
        }
    }
}

/// A protocol that represents an EventConvertible type, which must be able to be represented as an `Event`.
protocol EventConvertible {
    
    associatedtype Output
    associatedtype Failure: Swift.Error
    
    /// The `Event` representation of the object.
    var event: Event<Output, Failure> { get }
}

extension Event: EventConvertible {
    
    /// Provides the event itself as the Event representation.
    var event: Event<Output, Failure> { self }
}

extension Publisher {
    
    /// Transforms a Publisher to its materialized form, emitting `Event` values.
    func materialize() -> Publishers.Materialize<Self> {
        Publishers.Materialize(upstream: self)
    }
}

extension Publisher where Output: EventConvertible, Failure == Never {
    
    /// Extracts only the value events from a materialized Publisher.
    func values() -> AnyPublisher<Output.Output, Never> {
        compactMap {
            guard case .value(let value) = $0.event else { return nil }
            return value
        }
        .eraseToAnyPublisher()
    }
    
    /// Extracts only the failure events from a materialized Publisher.
    func failures() -> AnyPublisher<Output.Failure, Never> {
        compactMap {
            guard case .failure(let error) = $0.event else { return nil }
            return error
        }
        .eraseToAnyPublisher()
    }
}

extension Publishers {
    
    /// A type that represents a materialized Publisher.
    struct Materialize<U: Publisher>: Publisher {
        typealias Output = Event<U.Output, U.Failure>
        typealias Failure = Never
        
        private let upstream: U
        
        /// Initializer for `Materialize`.
        /// - Parameter upstream: The upstream publisher.
        init(upstream: U) {
            self.upstream = upstream
        }
        
        /// Attaches a subscriber to the publisher.
        /// - Parameter subscriber: The subscriber to receive events.
        func receive<S>(
            subscriber: S
        ) where Failure == S.Failure, Output == S.Input, S: Subscriber {
            subscriber.receive(
                subscription: MaterializeSubscription(
                    upstream: upstream,
                    downstream: subscriber
                )
            )
        }
    }
}

private extension Publishers.Materialize {
    
    /// A MaterializeSubscription for a Materialize publisher.
    class MaterializeSubscription<D: Subscriber>: Subscription
    where D.Input == Event<U.Output, U.Failure>, D.Failure == Never {
        
        private var sink: MaterializeSink<D>?
        
        /// Initializer for `MaterializeSubscription`.
        /// - Parameters:
        ///   - upstream: The upstream publisher.
        ///   - downstream: The downstream subscriber.
        init(upstream: U, downstream: D) {
            self.sink = .init(
                upstream: upstream,
                downstream: downstream,
                transformOutput: { .value($0) }
            )
        }
        
        /// Requests a demand from the publisher.
        /// - Parameter demand: The requested demand.
        func request(_ demand: Subscribers.Demand) {
            sink?.demand(demand)
        }
        
        /// Cancels the subscription.
        func cancel() {
            sink = nil
        }
    }
}

private extension Publishers.Materialize {
    /// A CCBSink for a Materialize publisher.
    class MaterializeSink<D: Subscriber>: CCBSink<U, D> where D.Input == Event<U.Output, U.Failure>,
                                                              D.Failure == Never {
        
        /// Receives a completion from an upstream publisher.
        /// - Parameter completion: A `Subscribers.Completion` case.
        override func receive(completion: Subscribers.Completion<U.Failure>) {
            // We're overriding the standard completion buffering mechanism
            // to buffer these events as regular materialized values, and send
            // a regular finished event in either case
            switch completion {
                case .finished:
                    _ = buffer.buffer(value: .finished)
                case .failure(let error):
                    _ = buffer.buffer(value: .failure(error))
            }
            
            buffer.complete(completion: .finished)
            cancelUpstream()
        }
    }
}
