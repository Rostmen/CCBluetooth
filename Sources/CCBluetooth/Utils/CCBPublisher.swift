//
//  CCBPublisher.swift
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

public typealias CCBPublisher<Output> = AnyPublisher<Output, CCBError>

/// An extension that provides helper methods for `BluetoothPublisher`.
extension CCBPublisher {
    /// Returns a publisher that emits a single value and then finishes.
    /// - Parameter element: The value to deliver to the subscriber.
    static func just<T>(_ element: T) -> CCBPublisher<T> {
        Just(element).setFailureType(to: CCBError.self).eraseToAnyPublisher()
    }

    /// Returns a publisher that terminates with the specified error.
    /// - Parameter error: The error to deliver to the subscriber.
    static func error<T>(_ error: CCBError) -> CCBPublisher<T> {
        Fail(error: error).eraseToAnyPublisher()
    }
}
