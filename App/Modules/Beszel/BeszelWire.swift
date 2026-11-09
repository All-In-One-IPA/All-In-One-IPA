import Foundation

/// Minimal deterministic CBOR for the numeric-key Beszel agent protocol.
/// Kept independent of third-party networking packages for a small extension-free binary.
indirect enum BeszelCBOR {
    case unsigned(UInt64)
    case negative(Int64)
    case bytes(Data)
    case text(String)
    case array([BeszelCBOR])
    case map([(UInt64, BeszelCBOR)])
    case stringMap([(String, BeszelCBOR)])
    case double(Double)
    case bool(Bool)
    case null

    func value(_ key: UInt64) -> BeszelCBOR? {
        if case .map(let values) = self {
            return values.first { $0.0 == key }?.1
        }
        return nil
    }
    var integer: UInt64? {
        if case .unsigned(let value) = self { return value }
        return nil
    }
    var byteData: Data? {
        if case .bytes(let value) = self { return value }
        return nil
    }
    var boolean: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
}

enum BeszelWire {
    static func encode(_ value: BeszelCBOR) -> Data {
        var output = Data()
        append(value, to: &output)
        return output
    }

    private static func head(_ major: UInt8, _ number: UInt64, _ data: inout Data) {
        let prefix = major << 5
        switch number {
        case 0..<24:
            data.append(prefix | UInt8(number))
        case 24...255:
            data.append(prefix | 24)
            data.append(UInt8(number))
        case 256...65535:
            data.append(prefix | 25)
            var v = UInt16(number).bigEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        case 65536...4294967295:
            data.append(prefix | 26)
            var v = UInt32(number).bigEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        default:
            data.append(prefix | 27)
            var v = number.bigEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
    }

    private static func append(_ value: BeszelCBOR, to data: inout Data) {
        switch value {
        case .unsigned(let n):
            head(0, n, &data)
        case .negative(let n):
            head(1, UInt64(-1 - n), &data)
        case .bytes(let content):
            head(2, UInt64(content.count), &data)
            data.append(content)
        case .text(let value):
            let content = Data(value.utf8)
            head(3, UInt64(content.count), &data)
            data.append(content)
        case .array(let values):
            head(4, UInt64(values.count), &data)
            for item in values { append(item, to: &data) }
        case .map(let values):
            head(5, UInt64(values.count), &data)
            for (key, item) in values {
                append(.unsigned(key), to: &data)
                append(item, to: &data)
            }
        case .stringMap(let values):
            head(5, UInt64(values.count), &data)
            for (key, item) in values {
                append(.text(key), to: &data)
                append(item, to: &data)
            }
        case .double(let v):
            data.append(0xfb)
            var bits = v.bitPattern.bigEndian
            withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
        case .bool(let v):
            data.append(v ? 0xf5 : 0xf4)
        case .null:
            data.append(0xf6)
        }
    }

    static func decode(_ bytes: Data) throws -> BeszelCBOR {
        var decoder = Decoder(bytes: Array(bytes))
        let value = try decoder.decode()
        guard decoder.offset == bytes.count else {
            throw ModuleOperationError("CBOR: лишние данные после сообщения.")
        }
        return value
    }

    private struct Decoder {
        let bytes: [UInt8]
        var offset: Int = 0

        mutating func byte() throws -> UInt8 {
            guard offset < bytes.count else {
                throw ModuleOperationError("CBOR: сообщение обрезано.")
            }
            defer { offset += 1 }
            return bytes[offset]
        }

        mutating func number(_ count: Int) throws -> UInt64 {
            guard count >= 0, count <= 8, offset <= bytes.count - count else {
                throw ModuleOperationError("CBOR: неверная длина.")
            }
            var value: UInt64 = 0
            for _ in 0..<count { value = (value << 8) | UInt64(try byte()) }
            return value
        }

        mutating func length(_ additional: UInt8) throws -> UInt64 {
            switch additional {
            case 0..<24: return UInt64(additional)
            case 24: return try number(1)
            case 25: return try number(2)
            case 26: return try number(4)
            case 27: return try number(8)
            default: throw ModuleOperationError("CBOR: неопределённая длина не поддерживается.")
            }
        }

        mutating func decode(depth: Int = 0) throws -> BeszelCBOR {
            guard depth < 24 else { throw ModuleOperationError("CBOR: вложенность превышена.") }
            let start = try byte()
            let major = start >> 5
            let arg = start & 31
            if major == 7 {
                switch arg {
                case 20: return .bool(false)
                case 21: return .bool(true)
                case 22: return .null
                case 26:
                    return .double(Double(Float(bitPattern: UInt32(try number(4)))))
                case 27:
                    return .double(Double(bitPattern: try number(8)))
                default:
                    throw ModuleOperationError("CBOR: неподдерживаемый простой тип.")
                }
            }
            let count = try length(arg)
            switch major {
            case 0: return .unsigned(count)
            case 1:
                guard count <= Int64.max else {
                    throw ModuleOperationError("CBOR: отрицательное число вне диапазона.")
                }
                return .negative(-1 - Int64(count))
            case 2, 3:
                guard count <= 1_048_576, UInt64(offset) + count <= UInt64(bytes.count) else {
                    throw ModuleOperationError("CBOR: размер поля превышен.")
                }
                let data = Data(bytes[offset..<(offset + Int(count))])
                offset += Int(count)
                if major == 2 { return .bytes(data) }
                guard let value = String(data: data, encoding: .utf8) else {
                    throw ModuleOperationError("CBOR: невалидный UTF-8.")
                }
                return .text(value)
            case 4:
                guard count <= 10000 else { throw ModuleOperationError("CBOR: слишком большой массив.") }
                var values: [BeszelCBOR] = []
                for _ in 0..<count { values.append(try decode(depth: depth + 1)) }
                return .array(values)
            case 5:
                guard count <= 10000 else { throw ModuleOperationError("CBOR: слишком большая карта.") }
                var numeric: [(UInt64, BeszelCBOR)] = []
                for _ in 0..<count {
                    let key = try decode(depth: depth + 1)
                    let value = try decode(depth: depth + 1)
                    guard case .unsigned(let n) = key else {
                        throw ModuleOperationError("CBOR: неожиданный тип ключа.")
                    }
                    numeric.append((n, value))
                }
                return .map(numeric)
            default: throw ModuleOperationError("CBOR: неизвестный тип.")
            }
        }
    }
}
