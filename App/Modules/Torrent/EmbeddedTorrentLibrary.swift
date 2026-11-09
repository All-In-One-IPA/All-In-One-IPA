import Foundation

// These symbols are exported by Rust/TorrentBridge as an iOS ARM64 static lib.
// The interface stays inside the app; no local HTTP server or external daemon.
@_silgen_name("aio_torrent_initialize")
private func aio_torrent_initialize(_ path: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_add_magnet")
private func aio_torrent_add_magnet(_ magnet: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_add_file")
private func aio_torrent_add_file(_ path: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_list")
private func aio_torrent_list() -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_pause")
private func aio_torrent_pause(_ id: UInt64) -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_resume")
private func aio_torrent_resume(_ id: UInt64) -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_remove")
private func aio_torrent_remove(_ id: UInt64, _ deleteFiles: Bool) -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_shutdown")
private func aio_torrent_shutdown() -> UnsafeMutablePointer<CChar>?
@_silgen_name("aio_torrent_free")
private func aio_torrent_free(_ result: UnsafeMutablePointer<CChar>)

enum EmbeddedTorrentLibrary {
    private static func unpack(_ pointer: UnsafeMutablePointer<CChar>?) throws -> [String: Any] {
        guard let pointer else {
            throw ModuleOperationError("librqbit не вернул ответ.")
        }
        let text = String(cString: pointer)
        aio_torrent_free(pointer)
        guard let bytes = text.data(using: .utf8),
              let response = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
            throw ModuleOperationError("librqbit вернул недопустимый JSON.")
        }
        guard response["ok"] as? Bool == true else {
            throw ModuleOperationError(response["error"] as? String ?? "Ошибка librqbit.")
        }
        return response["result"] as? [String: Any] ?? [:]
    }

    static func start(at folder: String) throws -> [String: Any] {
        try folder.withCString { try unpack(aio_torrent_initialize($0)) }
    }

    static func magnet(_ value: String) throws -> [String: Any] {
        try value.withCString { try unpack(aio_torrent_add_magnet($0)) }
    }

    static func torrentFile(at path: String) throws -> [String: Any] {
        try path.withCString { try unpack(aio_torrent_add_file($0)) }
    }

    static func list() throws -> [String: Any] {
        try unpack(aio_torrent_list())
    }

    static func pause(_ id: Int) throws {
        _ = try unpack(aio_torrent_pause(UInt64(id)))
    }

    static func resume(_ id: Int) throws {
        _ = try unpack(aio_torrent_resume(UInt64(id)))
    }

    static func remove(_ id: Int, files: Bool) throws {
        _ = try unpack(aio_torrent_remove(UInt64(id), files))
    }

    static func shutdown() throws {
        _ = try unpack(aio_torrent_shutdown())
    }
}
