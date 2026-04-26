#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("unsupported platform")
#endif

import SystemPackage

extension FilePath.Directory {
    /// An unsafe interface for iterating directory entries from a directory pointer.
    struct Stream: ~Copyable {
        private var pointer: FilePath.DirectoryPointer?

        private init(pointer: FilePath.DirectoryPointer?) {
            self.pointer = pointer
        }

        deinit {
            if  let stream: FilePath.DirectoryPointer = self.pointer {
                closedir(stream)
            }
        }
    }
}
extension FilePath.Directory.Stream {
    private static let dirent: DirentOffsets = .load
}
extension FilePath.Directory.Stream {
    static var empty: Self { .init(pointer: nil) }

    static func open(
        _ directory: FilePath.Directory
    ) throws(FileError) -> Self {
        let pointer: FilePath.DirectoryPointer? = directory.path.withPlatformString(opendir)
        if  case nil = pointer {
            switch Errno.init(rawValue: errno) {
            case .notDirectory:
                break
            case let errno:
                throw .init(type: .opening(directory.path, errno))
            }
        }
        return .init(pointer: pointer)
    }

    mutating func next() -> (FilePath.Component, FileType?)? {
        guard let stream: FilePath.DirectoryPointer = self.pointer else {
            return nil
        }

        while let entry: UnsafeMutablePointer<dirent> = readdir(stream) {
            let name: FilePath.Component = Self.dirent.name(from: entry)
            let type: FileType?

            #if canImport(Darwin)
            typealias DType = Int32
            #else
            typealias DType = Int
            #endif

            switch DType.init(entry.pointee.d_type) {
            case DT_DIR: type = .directory
            case DT_REG: type = .regular
            case DT_LNK: type = .symlink
            case DT_BLK: type = .blockDevice
            case DT_CHR: type = .characterDevice
            case DT_FIFO: type = .fifo
            case DT_SOCK: type = .socket
            default: type = nil
            }

            // ignore `.` and `..`
            if  case .regular = name.kind {
                return (name, type)
            } else {
                continue
            }
        }

        closedir(stream)
        self.pointer = nil
        return nil
    }
}
