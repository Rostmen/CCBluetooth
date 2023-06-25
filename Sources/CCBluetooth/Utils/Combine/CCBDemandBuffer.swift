//
//  CCBDemandBuffer.swift
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

/// A buffer that regulates the demand between a `Publisher` and `Subscriber`.
class CCBDemandBuffer<S: Subscriber> {
    
    /// Recursive lock for protecting access to `buffer`, `completion`, and `demandState`.
    private let lock = NSRecursiveLock()
    
    /// An array of input values from the subscriber.
    private var buffer = [S.Input]()
    
    /// The subscriber that receives values and completion.
    private let subscriber: S
    
    /// A stored subscriber completion state.
    private var completion: Subscribers.Completion<S.Failure>?
    
    /// The state of the demand.
    private var demandState = Demand()
    
    /// Creates a new demand buffer for the provided subscriber.
    ///
    /// - Parameter subscriber: The subscriber that will receive values and completion.
    init(subscriber: S) {
        self.subscriber = subscriber
    }
    
    /// Buffers a value from the publisher to send to the subscriber when demand exists.
    ///
    /// - Parameter value: The input value from the publisher.
    /// - Returns: The number of requested values that haven't been delivered yet.
    func buffer(value: S.Input) -> Subscribers.Demand {
        precondition(self.completion == nil, "Completion must be nil")
        
        switch demandState.requested {
            case .unlimited:
                return subscriber.receive(value)
            default:
                buffer.append(value)
                return flush()
        }
    }
    
    /// Completes the subscription with a completion event.
    ///
    /// - Parameter completion: A `Subscribers.Completion` event indicating that the publisher has finished sending
    /// events.
    func complete(completion: Subscribers.Completion<S.Failure>) {
        precondition(self.completion == nil, "Completion have already occured")
        
        self.completion = completion
        _ = flush()
    }
    
    /// Requests the specified number of values from the publisher.
    ///
    /// - Parameter demand: The number of values to request from the publisher.
    /// - Returns: The number of requested values that haven't been delivered yet.
    func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
        flush(adding: demand)
    }
    
    /// Flushing buffer by sending as many values as possible to the subscriber.
    ///
    /// - Parameter newDemand: The newly requested demand.
    /// - Returns: The number of requested values that haven't been delivered yet.
    private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
        lock.lock()
        defer { lock.unlock() }
        
        if let newDemand = newDemand {
            demandState.requested += newDemand
        }
        
        guard
            demandState.requested > 0 ||
                newDemand == Subscribers.Demand.none
        else { return .none }
        
        while !buffer.isEmpty && demandState.processed < demandState.requested {
            demandState.requested += subscriber.receive(buffer.remove(at: 0))
            demandState.processed += 1
        }
        
        if let completion = completion {
            buffer = []
            demandState = .init()
            self.completion = nil
            subscriber.receive(completion: completion)
            return .none
        }
        
        let sentDemand = demandState.requested - demandState.sent
        demandState.sent += sentDemand
        return sentDemand
    }
}

private extension CCBDemandBuffer {
    
    /// A structure that holds the state of the demand.
    struct Demand {
        var processed: Subscribers.Demand = .none
        var requested: Subscribers.Demand = .none
        var sent: Subscribers.Demand = .none
    }
}

extension Subscription {
    
    /// Requests values from the publisher if demand is greater than zero.
    ///
    /// - Parameter demand: The number of values to request from the publisher.
    func requestIfNeeded(_ demand: Subscribers.Demand) {
        guard demand > .none else { return }
        request(demand)
    }
}

extension Optional where Wrapped == Subscription {
    
    /// Cancels the subscription and sets it to nil.
    mutating func kill() {
        self?.cancel()
        self = nil
    }
}
