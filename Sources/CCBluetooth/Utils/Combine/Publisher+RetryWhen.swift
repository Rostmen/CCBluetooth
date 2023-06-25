//
//  Publisher+RetryWhen.swift
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

/// Type alias for a publisher that emits a Failure and never completes.
typealias RetryWhenFailurePublisher<Failure: Error> = AnyPublisher<Failure, Never>

extension Publisher {
    /// Retries the operation on the publisher when the handler emits a new item.
    ///
    /// - Parameter handler: A closure that consumes a publisher of failures and outputs a publisher whose emissions cause
    /// the retry operation.
    /// - Returns: A publisher that mirrors the source publisher, retrying on failures as specified by the handler.
    func retryWhen<P>(
        _ handler: @escaping (RetryWhenFailurePublisher<Self.Failure>) -> P
    ) -> Publishers.RetryWhen<Self, P> where P: Publisher, P.Failure == Self.Failure {
        Publishers.RetryWhen(source: self, handler: handler)
    }
}

extension Publishers {
    /// A publisher that retries the operation of the source publisher when the handler emits a new item.
    final class RetryWhen<S, H>: Publisher where S: Publisher, H: Publisher,
                                                 H.Failure == S.Failure {
        typealias Output = S.Output
        typealias Failure = S.Failure

        private let source: S
        private let handler: (AnyPublisher<Failure, Never>) -> H

        /// Initializes a new `RetryWhen` publisher.
        ///
        /// - Parameters:
        ///   - source: The original publisher.
        ///   - handler: A closure that consumes a publisher of failures and outputs a publisher whose emissions cause the retry
        ///   operation.
        init(source: S, handler: @escaping (AnyPublisher<Failure, Never>) -> H) {
            self.source = source
            self.handler = handler
        }

        /// This function is called when this Publisher is subscribed to.
        ///
        /// - Parameter subscriber: The subscriber for this publisher.
        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let subject = CurrentValueSubject<Optional<Failure>, Never>(nil)
            handler(
                subject.compactMap { $0 }.eraseToAnyPublisher()
            )
            .map { Optional.some($0) }
            .prepend(nil)
            .flatMap { [source] _ in
                source.handleEvents(receiveCompletion: { completion in
                    if case .finished = completion {
                        subject.send(completion: .finished)
                    }
                }, receiveCancel: {
                    subject.send(completion: .finished)
                })
                .catch { (error) -> AnyPublisher<Output, Failure> in
                    Empty().handleEvents(receiveSubscription: { _ in
                        subject.send(error)
                    })
                    .eraseToAnyPublisher()
                }
            }
            .subscribe(subscriber)
        }
    }
}

