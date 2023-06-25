# CCBluetooth
Apple's CoreBluetooth + Combine

CCBluetooth is a library that puts Apple's `CoreBluetooth` framework on Apple's reactive `Combine` framework. If you tired of managing CoreBluetooth delegates, states this library is for you. In addition this library has no third-party dependecies.

Inspired by [RxBluetoothKit](https://github.com/Polidea/RxBluetoothKit) for RxSwift.

## Requirements:

- iOS 13, tvOS 13, macOS 10.15, or watchOS 6
- Xcode 12 or higher
- Swift 5.3 or higher

## Installation

### Swift Package Manager

Add this line to your dependencies list in your Package.swift:

```swift
.package(name: "CCBluetooth", url: "https://github.com/Rostmen/CCBluetooth.git", from: "0.0.1"),
```

## Usage

```
let manager = CCBCentralManager()
manager
    /// Scan peripheral with service uuid "3bdfdcee-13b1-11ee-be56-0242ac120002"
    .scan(services: [
        CBUUID(string: "3bdfdcee-13b1-11ee-be56-0242ac120002")
    ])
    /// Takes first result
    .first()
    .flatMap { scanResult in
        /// Establish connection to scanned peripheral
        manager.establishConnection(peripheral: scanResult.peripheral)
    }
    .flatMap { connectedPeripheral in
        /// Discover services on connected peripheral
        connectedPeripheral.discoverServices([
            CBUUID(string: "3bdfdcee-13b1-11ee-be56-0242ac120002")
        ])
        /// Takes first service
        .compactMap(\.first)
        .flatMap { service in
            /// Discover characteristic with uuid "2388d510-13b1-11ee-be56-0242ac120002"
            connectedPeripheral.discoverCharacteristics([
                CBUUID(string: "2388d510-13b1-11ee-be56-0242ac120002")
            ], for: service)
        }
        /// Takes first service
        .compactMap(\.first)
        /// Turn on value update on characteristic and subscribes on new values
        .flatMap(connectedPeripheral.observeValueUpdateAndSetNotification)
        /// Takes `Data` object
        .compactMap(\.value)
    }
```

# Support

* [Contact me](mailto:kobizsky@gmail.com)
* [LinkedIn](https://www.linkedin.com/in/kobizsky)
