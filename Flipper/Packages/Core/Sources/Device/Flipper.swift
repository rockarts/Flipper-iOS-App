import Peripheral

import struct Foundation.UUID

public struct Flipper: Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public var color: FlipperColor
    public var state: FlipperState = .disconnected
    public var information: DeviceInformation?
    public var battery: Battery?
    public var storage: StorageInfo?

    // swiftlint:disable discouraged_optional_boolean
    public var hasProtobufVersion: Bool?

    public init(
        id: UUID,
        name: String,
        color: FlipperColor,
        state: FlipperState = .disconnected,
        information: DeviceInformation? = nil,
        battery: Battery? = nil,
        hasProtobufVersion: Bool = false
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.state = state
        self.information = information
        self.battery = battery
        self.hasProtobufVersion = hasProtobufVersion
    }

    public struct StorageInfo: Equatable {
        public var `internal`: StorageSpace?
        public var external: StorageSpace?
    }
}

fileprivate extension String {
    static var deviceInformation: String { "Device Information" }
    static var battery: String { "Battery" }
}

public extension Flipper {
    init(_ source: BluetoothPeripheral) {
        self.id = source.id
        self.name = source.name
        self.color = source.color
        self.state = source.state

        self.information = source.services
            .first { $0.id == .deviceInformation }
            .map(DeviceInformation.init) ?? nil

        self.battery = source.services
            .first { $0.id == .battery }
            .map(Battery.init) ?? nil

        self.hasProtobufVersion = source.hasProtobufVersion
    }
}

fileprivate extension String {
    static var manufacturerName: String { "Manufacturer Name String" }
    static var serialNumber: String { "Serial Number String" }
    static var firmwareRevision: String { "Firmware Revision String" }
    static var softwareRevision: String { "Software Revision String" }
    static var protobufUUID: String { "03F6666D-AE5E-47C8-8E1A-5D873EB5A933" }
}

fileprivate extension Flipper.DeviceInformation {
    init?(_ service: FlipperService) {
        guard service.id == .deviceInformation else { return nil }

        let manufacturerName = service.characteristics
            .first { $0.name == .manufacturerName }?.value ?? []
        let serialNumber = service.characteristics
            .first { $0.name == .serialNumber }?.value ?? []
        let firmwareRevision = service.characteristics
            .first { $0.name == .firmwareRevision }?.value ?? []
        let softwareRevision = service.characteristics
            .first { $0.name == .softwareRevision }?.value ?? []
        let protobufRevision = service.characteristics
            .first { $0.name == .protobufUUID }?.value ?? []

        self.init(
            manufacturerName: manufacturerName,
            serialNumber: serialNumber,
            firmwareRevision: firmwareRevision,
            softwareRevision: softwareRevision,
            protobufRevision: protobufRevision)
    }
}

fileprivate extension Flipper.Battery {
    init?(_ service: FlipperService) {
        guard
            service.id == .battery,
            let characteristic = service.characteristics.first,
            !characteristic.value.isEmpty
        else {
            return nil
        }
        self.init(level: Int(characteristic.value[0]))
    }
}
