//
//  Publisher+Enumerated.swift
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
    /// Transforms the output of this publisher by assigning it a running index and returns it as a tuple.
    /// This can be useful for getting the index of each element as part of the stream.
    ///
    /// - Returns: An `AnyPublisher` instance that emits tuples where each tuple contains
    /// the index of the item and the item itself. The counting starts from zero.
    /// If the publisher fails, the failure will be propagated downstream.
    func enumerated() -> AnyPublisher<(Int, Self.Output), Self.Failure> {
        scan(Optional<(Int, Self.Output)>.none) { acc, next in
            guard let acc = acc else { return (0, next) }
            return (acc.0 + 1, next)
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }
}
