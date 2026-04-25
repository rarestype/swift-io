import SystemPackage

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

        guard let offset: Int = MemoryLayout<dirent>.offset(of: \.d_name) else {
            fatalError("invalid `dirent` layout")
        }
        while let entry: UnsafeMutablePointer<dirent> = readdir(stream) {
            // `entry` is likely statically-allocated, and has variable-length layout.
            //  attemping to unbind or rebind memory would be meaningless, as we must
            //  rely on the kernel to protect us from buffer overreads.
            let field: UnsafeMutableRawPointer = .init(entry) + offset
            let name: UnsafeMutablePointer<CInterop.PlatformChar> = field.assumingMemoryBound(
                to: CInterop.PlatformChar.self
            )

            guard let component: FilePath.Component = .init(platformString: name) else {
                fatalError("could not read platform string from `dirent.d_name`")
            }
            // ignore `.` and `..`
            if  case .regular = component.kind {
                return component
            } else {
                continue
            }
        }

        closedir(stream)
        self.pointer = nil
        return nil
    }
}
