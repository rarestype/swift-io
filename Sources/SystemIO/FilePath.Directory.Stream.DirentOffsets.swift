import SystemPackage

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("unsupported platform")
#endif

extension FilePath.Directory.Stream {
    struct DirentOffsets {
        private let name: Int
    }
}
extension FilePath.Directory.Stream.DirentOffsets {
    static var load: Self {
        guard
        let name: Int = MemoryLayout<dirent>.offset(of: \.d_name) else {
            fatalError("invalid `dirent` layout")
        }
        return .init(name: name)
    }
}
extension FilePath.Directory.Stream.DirentOffsets {
    func name(from base: UnsafeMutablePointer<dirent>) -> FilePath.Component {
        // `base` is likely statically-allocated, and has variable-length layout.
        //  attemping to unbind or rebind memory would be meaningless, as we must
        //  rely on the kernel to protect us from buffer overreads.
        let name: UnsafeMutableRawPointer = .init(base) + self.name
        guard
        let name: FilePath.Component = .init(
            platformString: name.assumingMemoryBound(to: CInterop.PlatformChar.self)
        ) else {
            fatalError("could not read platform string from `dirent.d_name`")
        }

        return name
    }
}
