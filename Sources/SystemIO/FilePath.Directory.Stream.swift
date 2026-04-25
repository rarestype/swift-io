#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("unsupported platform")
#endif

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
            case let error:
                throw .opening(directory.path, error)
            }
        }
        return .init(pointer: pointer)
    }

    mutating func next() -> FilePath.Component? {
        guard let stream: FilePath.DirectoryPointer = self.pointer else {
            return nil
        }

        while let entry: UnsafeMutablePointer<dirent> = readdir(stream) {
            let name: FilePath.Component = Self.dirent.name(from: entry)
            // ignore `.` and `..`
            if  case .regular = name.kind {
                return name
            } else {
                continue
            }
        }

        closedir(stream)
        self.pointer = nil
        return nil
    }
}
