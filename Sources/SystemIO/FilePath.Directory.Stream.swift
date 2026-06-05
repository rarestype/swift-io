#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc

// WASI dirent.h macro polyfills
var DT_UNKNOWN: Int32 { 0 }
var DT_FIFO: Int32 { 1 }
var DT_CHR: Int32 { 2 }
var DT_DIR: Int32 { 4 }
var DT_BLK: Int32 { 6 }
var DT_REG: Int32 { 8 }
var DT_LNK: Int32 { 10 }

#else
#error("unsupported platform")
#endif

internal import SystemCalls
internal import SystemPackage

extension FilePath.Directory {
    /// An unsafe interface for iterating directory entries from a directory pointer.
    struct Stream: ~Copyable {
        private var pointer: SystemCall.DirectoryPointer?

        private init(pointer: SystemCall.DirectoryPointer?) {
            self.pointer = pointer
        }

        deinit {
            if  let stream: SystemCall.DirectoryPointer = self.pointer {
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
        let result: Result<
            SystemCall.DirectoryPointer?,
            FileError
        > = directory.path.withPlatformString {
            do throws (SystemCallErrorType) {
                return .success(try SystemCall._opendir($0))
            } catch ._ENOTDIR {
                return .success(nil)
            } catch let error {
                return .failure(FileError.init(type: .opening(directory.path, error)))
            }
        }
        return .init(pointer: try result.get())
    }

    mutating func next() -> (FilePath.Component, FileType?)? {
        guard let stream: SystemCall.DirectoryPointer = self.pointer else {
            return nil
        }

        while let entry: UnsafeMutablePointer<dirent> = readdir(stream) {
            let name: FilePath.Component = Self.dirent.name(from: entry)
            let type: FileType?

            #if canImport(Darwin)
            typealias DType = Int32
            #elseif canImport(WASILibc)
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
