import SystemPackage

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
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
        #if os(WASI)
        // Swift cannot import C flexible array members (char d_name[]).
        // We compute the offset manually: it starts immediately after d_type.
        guard
        let last: Int = MemoryLayout<dirent>.offset(of: \.d_type) else {
            fatalError("invalid `dirent` layout")
        }
        // d_type is unsigned char
        let name: Int = last + MemoryLayout<UInt8>.size

        #else
        guard
        let name: Int = MemoryLayout<dirent>.offset(of: \.d_name) else {
            fatalError("invalid `dirent` layout")
        }
        #endif
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
