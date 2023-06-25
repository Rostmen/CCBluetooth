//
//  Publisher+ReplaceEmptyWith.swift
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

    /// Replaces an empty publisher with a provided alternative publisher.
    ///
    /// - Parameter alternative: A publisher to use as a replacement when the source publisher is empty.
    /// - Returns: A publisher that emits the output from this publisher, or from an alternative publisher if this publisher finishes
    /// without emitting any output.
    func replaceEmpty<P>(with alternative: P) -> Publishers.ReplaceEmptyWith<Self, P>
    where P: Publisher, P.Failure == Self.Failure {
        Publishers.ReplaceEmptyWith(source: self, alternative: alternative)
    }

    /// Replaces an empty publisher with a failure event.
    ///
    /// - Parameter failure: A failure to emit when the source publisher is empty.
    /// - Returns: A publisher that emits the output from this publisher, or a failure if this publisher finishes without emitting
    /// any output.
    func replaceEmpty(
        with failure: Failure
    ) -> Publishers.ReplaceEmptyWith<Self, Fail<Output, Failure>> {
        replaceEmpty(with: Fail<Self.Output, Self.Failure>(error: failure))
    }
}

extension Publishers {

    /// A publisher that replaces an empty publisher with a provided alternative publisher or a failure.
    final class ReplaceEmptyWith<S, A>: Publisher where S: Publisher, A: Publisher,
                                                        A.Output == S.Output,
                                                        A.Failure == S.Failure {
        typealias Output = S.Output
        typealias Failure = S.Failure

        private let source: S
        private let alternative: A

        /// Creates a new `ReplaceEmptyWith` publisher.
        ///
        /// - Parameters:
        ///   - source: The original publisher.
        ///   - alternative: The alternative publisher to use when the original publisher is empty.
        init(source: S, alternative: A) {
            self.source = source
            self.alternative = alternative
        }

        /// An error indicating that the source publisher is empty.
        enum FailureE: Error {
            case empty
        }

        /// This function is called when this Publisher is subscribed to.
        ///
        /// The default implementation of this function never calls the provided closure.
        ///
        /// - Parameter subscriber: The subscriber for this publisher.
        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            source
                .map { Result<Output, Error>.success($0) }
                .replaceEmpty(with: .failure(FailureE.empty))
                .flatMap { [alternative] res -> AnyPublisher<Output, Failure> in
                    switch res {
                        case .success(let output):
                            return Just(output)
                                .setFailureType(to: Failure.self)
                                .eraseToAnyPublisher()
                        case .failure(FailureE.empty):
                            return alternative.eraseToAnyPublisher()
                        case .failure(let error as Failure):
                            return Fail<Output, Failure>(error: error).eraseToAnyPublisher()
                        case .failure(_):
                            return Empty().eraseToAnyPublisher()
                    }
                }
                .subscribe(subscriber)
        }
    }
}
