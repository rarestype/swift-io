#if canImport(Darwin)

public import Darwin

#elseif canImport(Glibc)

public import Glibc

#elseif canImport(WASILibc)

public import WASILibc

#else
#error("unsupported platform")
#endif

@frozen public enum SystemCall {}
extension SystemCall {
    @inlinable public static func _fstat(
        _ file: Int32,
    ) throws(SystemCallErrorType) -> stat {
        var result: stat = .init()
        let status: Int32 = fstat(file, &result)
        if  status == 0 {
            return result
        } else {
            throw .init(errno: errno)
        }
    }
    @inlinable public static func _getcwd<T>(
        _ yield: (UnsafeMutablePointer<CChar>) -> T
    ) throws(SystemCallError) -> T {
        guard
        let buffer: UnsafeMutablePointer<CChar> = getcwd(nil, 0) else {
            throw .init(type: .init(errno: errno), call: .getcwd)
        }
        defer {
            free(buffer)
        }
        return yield(buffer)
    }

    @inlinable public static func _mkdir(
        _ path: UnsafePointer<CChar>,
        _ mode: mode_t
    ) throws(SystemCallErrorType) {
        let status: Int32 = mkdir(path, mode)
        if  status != 0 {
            throw .init(errno: errno)
        }
    }

    @inlinable public static func _opendir(
        _ path: UnsafePointer<CChar>
    ) throws(SystemCallErrorType) -> DirectoryPointer {
        if  let pointer: DirectoryPointer = opendir(path) {
            return pointer
        } else {
            throw .init(errno: errno)
        }
    }

    @inlinable public static func _remove(
        _ path: UnsafePointer<CChar>
    ) throws(SystemCallErrorType) {
        let status: Int32 = remove(path)
        if  status != 0 {
            throw .init(errno: errno)
        }
    }

    @inlinable public static func _stat(
        _ path: UnsafePointer<CChar>,
    ) throws(SystemCallErrorType) -> stat {
        var result: stat = .init()
        let status: Int32 = stat(path, &result)
        if  status == 0 {
            return result
        } else {
            throw .init(errno: errno)
        }
    }

    #if !os(WASI)
    @inlinable public static func _statvfs(
        _ path: UnsafePointer<CChar>,
    ) throws(SystemCallErrorType) -> statvfs {
        var result: statvfs = .init()
        let status: Int32 = statvfs(path, &result)
        if  status == 0 {
            return result
        } else {
            throw .init(errno: errno)
        }
    }
    #endif
}
