//
//  Publisher+Void.swift
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

/// An extension of the Publisher protocol where the Output is Void.
extension Publisher where Output == Void {

    /// Creates a Publisher that will emit a `Void` signal after a specified time interval.
    ///
    /// - Parameters:
    ///   - interval: The time to wait before emitting the `Void` signal.
    ///   - queue: The DispatchQueue on which to emit the `Void` signal. Defaults to a background queue.
    /// - Returns: A Publisher that emits a `Void` signal after the specified time interval.
    static func timeout(
        interval: DispatchQueue.SchedulerTimeType.Stride,
        queue: DispatchQueue = .global(qos: .background)
    ) -> AnyPublisher<Void, Failure> {
        Deferred {
            Future { p in
                queue.asyncAfter(
                    deadline: .now() + interval.timeInterval,
                    execute: { p(.success(())) }
                )
            }
        }
        .setFailureType(to: Failure.self)
        .eraseToAnyPublisher()
    }
    
    /// Creates a Publisher that immediately emits an error.
    ///
    /// - Parameter error: The error to be emitted.
    /// - Returns: A Publisher that emits the specified error.
    static func failure(error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error).eraseToAnyPublisher()
    }
}

extension Publishers {

    /// A collection of methods for creating delayed Publishers.
    enum Delayed {

        /// Creates a Publisher that emits a single value after a specified time interval.
        ///
        /// - Parameters:
        ///   - output: The value to be emitted.
        ///   - interval: The time to wait before emitting the value.
        ///   - queue: The DispatchQueue on which to emit the value. Defaults to a background queue.
        /// - Returns: A Publisher that emits a single value after the specified time interval.
        static func just<T>(
            _ output: T,
            interval: DispatchQueue.SchedulerTimeType.Stride,
            queue: DispatchQueue = .global(qos: .background)
        ) -> Deferred<Publishers.Delay<Just<T>, DispatchQueue>> {
            Deferred { Just(output).delay(for: interval, scheduler: queue) }
        }
        
        /// Creates a Publisher that emits an error after a specified time interval.
        ///
        /// - Parameters:
        ///   - failure: The error to be emitted.
        ///   - interval: The time to wait before emitting the error.
        ///   - queue: The DispatchQueue on which to emit the error. Defaults to a background queue.
        /// - Returns: A Publisher that emits an error after the specified time interval.
        static func error<Output, Failure: Error>(
            _ failure: Failure,
            interval: DispatchQueue.SchedulerTimeType.Stride,
            queue: DispatchQueue = .global(qos: .background)
        ) -> Deferred<Publishers.Delay<Fail<Output, Failure>, DispatchQueue>> {
            Deferred { Fail(error: failure).delay(for: interval, scheduler: queue) }
        }
    }
}
