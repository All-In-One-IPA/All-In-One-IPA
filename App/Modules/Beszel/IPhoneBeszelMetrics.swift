import Foundation
import UIKit
import Darwin
import CryptoKit

/// A subset of device-wide metrics that an ordinary sandboxed iOS app can read.
/// No private APIs or invented CPU/memory readings.
@MainActor
final class IPhoneBeszelMetrics {
    private var lastCpuTicks: [UInt64]?

    func snapshot(name: String, includeDetails: Bool) -> BeszelCBOR {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let uptime = UInt64(max(0, ProcessInfo.processInfo.systemUptime))
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = memoryUsage()
        let disk = diskSpace()
        let cpu = cpuUsage()
        let batteryValue = UIDevice.current.batteryLevel
        let batteryPercent = batteryValue < 0 ? UInt64(0) : UInt64(min(100, max(0, Int(batteryValue * 100))))
        let batteryState: UInt64 = UIDevice.current.batteryState == .charging ||
            UIDevice.current.batteryState == .full ? 1 : 0
        let memoryPercent = totalMemory == 0 || usedMemory == nil ? 0 :
            Double(usedMemory!) / Double(totalMemory) * 100
        let diskPercent = disk.total > 0 ? Double(disk.used) / Double(disk.total) * 100 : 0
        let gb = 1024.0 * 1024 * 1024

        var stats: [(UInt64, BeszelCBOR)] = [
            (0, .double(cpu ?? 0)),
            (2, .double(Double(totalMemory) / gb)),
            (3, .double(Double(usedMemory ?? 0) / gb)),
            (4, .double(memoryPercent)),
            (9, .double(Double(disk.total) / gb)),
            (10, .double(Double(disk.used) / gb)),
            (11, .double(diskPercent)),
            (29, .array([.unsigned(batteryPercent), .unsigned(batteryState)])),
            (41, .array([
                .unsigned(totalMemory), .unsigned(usedMemory ?? 0), .unsigned(0), .unsigned(0)
            ]))
        ]
        if cpu == nil { stats.removeAll { $0.0 == 0 } }
        if usedMemory == nil {
            stats.removeAll { $0.0 == 3 || $0.0 == 4 || $0.0 == 41 }
        }

        let info: [(UInt64, BeszelCBOR)] = [
            (0, .text(name)),
            (3, .unsigned(UInt64(ProcessInfo.processInfo.activeProcessorCount))),
            (5, .unsigned(uptime)),
            (6, .double(cpu ?? 0)),
            (7, .double(memoryPercent)),
            (8, .double(diskPercent)),
            (10, .text("0.21.1")),
            (14, .unsigned(1)),  // Darwin: Beszel system.Os
            (20, .unsigned(2)),  // WebSocket
            (23, .array([.unsigned(batteryPercent), .unsigned(batteryState)]))
        ]

        var data: [(UInt64, BeszelCBOR)] = [
            (0, .map(stats)),
            (1, .map(info)),
            (2, .array([])),
            (6, .map([]))
        ]

        if includeDetails {
            let details: [(UInt64, BeszelCBOR)] = [
                (0, .text(name)),
                (1, .text(UIDevice.current.systemVersion)),
                (2, .unsigned(UInt64(ProcessInfo.processInfo.processorCount))),
                (3, .unsigned(UInt64(ProcessInfo.processInfo.activeProcessorCount))),
                (4, .text("Apple mobile")),
                (5, .unsigned(1)),
                (6, .text("iOS " + UIDevice.current.systemVersion)),
                (7, .text("arm64")),
                (9, .unsigned(totalMemory))
            ]
            data.append((4, .map(details)))
        }

        return .map(data)
    }

    private func diskSpace() -> (total: UInt64, used: UInt64) {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let total = attrs[.systemSize] as? NSNumber,
              let free = attrs[.systemFreeSize] as? NSNumber else {
            return (0, 0)
        }
        return (total.uint64Value, total.uint64Value &- min(total.uint64Value, free.uint64Value))
    }

    private func memoryUsage() -> UInt64? {
        var vm = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride /
                                            MemoryLayout<integer_t>.stride)
        let code = withUnsafeMutablePointer(to: &vm) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { fields in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, fields, &count)
            }
        }
        guard code == KERN_SUCCESS else { return nil }
        let pages = UInt64(vm.active_count) + UInt64(vm.wire_count) +
                    UInt64(vm.compressor_page_count)
        return pages * UInt64(vm_kernel_page_size)
    }

    private func cpuUsage() -> Double? {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride /
                                            MemoryLayout<integer_t>.stride)
        let code = withUnsafeMutablePointer(to: &load) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { fields in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, fields, &count)
            }
        }
        guard code == KERN_SUCCESS else { return nil }
        let ticks: [UInt64] = withUnsafeBytes(of: load.cpu_ticks) { buffer in
            Array(buffer.bindMemory(to: UInt32.self)).map(UInt64.init)
        }
        defer { lastCpuTicks = ticks }
        guard let previous = lastCpuTicks, previous.count == ticks.count else { return nil }
        let deltas = zip(ticks, previous).map { $0.0 &- min($0.0, $0.1) }
        let total = deltas.reduce(0, +)
        guard total > 0 else { return nil }
        return min(100, max(0, Double(total &- deltas[Int(CPU_STATE_IDLE)]) / Double(total) * 100))
    }

    static func persistentFingerprint() -> String {
        let key = "aio.beszel.agentFingerprintSource"
        let stored: String
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            stored = existing
        } else {
            stored = UUID().uuidString
            UserDefaults.standard.set(stored, forKey: key)
        }
        return SHA256.hash(data: Data(stored.utf8)).prefix(24)
            .map { String(format: "%02x", $0) }.joined()
    }
}

enum BeszelHubIdentity {
    /// SSH wire format: length + "ssh-ed25519" + length + 32-byte public key.
    static func publicKey(from text: String) throws -> Curve25519.Signing.PublicKey {
        let fields = text.split(whereSeparator: \.isWhitespace)
        guard fields.count >= 2, fields[0] == "ssh-ed25519",
              let raw = Data(base64Encoded: String(fields[1])) else {
            throw ModuleOperationError("Нужен открытый ключ KEY в формате ssh-ed25519 AAAA… из Beszel Hub.")
        }
        var position = 0
        func read() throws -> Data {
            guard raw.count >= position + 4 else { throw ModuleOperationError("Ключ SSH повреждён.") }
            let size = raw[position..<(position + 4)].reduce(UInt32(0)) {
                ($0 << 8) | UInt32($1)
            }
            position += 4
            guard size <= 1024, raw.count >= position + Int(size) else {
                throw ModuleOperationError("Ключ SSH имеет неверную длину.")
            }
            let output = Data(raw[position..<(position + Int(size))])
            position += Int(size)
            return output
        }
        guard try String(data: read(), encoding: .utf8) == "ssh-ed25519" else {
            throw ModuleOperationError("Это не ключ Ed25519.")
        }
        let key = try read()
        guard position == raw.count, key.count == 32 else {
            throw ModuleOperationError("Неверный размер открытого ключа.")
        }
        return try Curve25519.Signing.PublicKey(rawRepresentation: key)
    }
}
