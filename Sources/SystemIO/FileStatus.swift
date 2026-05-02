#if canImport(Darwin)
public import Darwin
#elseif canImport(Glibc)
public import Glibc
#else
#error("unsupported platform")
#endif

import struct SystemPackage.Errno

@frozen public struct FileStatus {
    @usableFromInline let value: stat

    private init(value: stat) {
        self.value = value
    }
}
extension FileStatus {
    var id: FileIdentifier {
        .init(dev: self.value.st_dev, ino: self.value.st_ino)
    }
}
extension FileStatus {
    @inlinable public func `is`(_ type: FileType) -> Bool {
        self.value.st_mode & S_IFMT == type.mask
    }

    @inlinable public var type: FileType? {
        switch self.value.st_mode & S_IFMT {
        case S_IFBLK: .blockDevice
        case S_IFCHR: .characterDevice
        case S_IFDIR: .directory
        case S_IFIFO: .fifo
        case S_IFREG: .regular
        case S_IFSOCK: .socket
        case S_IFLNK: .symlink
        default: nil
        }
    }
}
extension FileStatus {
    public static func status(of file: FileDescriptor) throws -> Self { try .init(file: file) }

    @available(*, deprecated, message: "use 'FilePath.status' instead")
    public static func status(of path: FilePath) throws -> Self { try .init(path: path) }
}
extension FileStatus {
    init(file: borrowing FileDescriptor) throws(Errno) {
        var value: stat = .init()
        switch fstat(file.rawValue, &value) {
        case 0: self.init(value: value)
        case _: throw Errno.init(rawValue: errno)
        }
    }
    init(path: borrowing FilePath) throws(Errno) {
        var value: stat = .init()
        switch path.withPlatformString({ stat($0, &value) }) {
        case 0: self.init(value: value)
        case _: throw .init(rawValue: errno)
        }
    }
}
