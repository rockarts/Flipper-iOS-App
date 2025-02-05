import CryptoKit

public struct Hash: Equatable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(_ bytes: [UInt8]) {
        self.init(.init(decoding: bytes, as: UTF8.self))
    }
}

public extension String {
    var md5: String {
        Insecure.MD5.hash(data: data(using: .utf8) ?? .init()).map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}
