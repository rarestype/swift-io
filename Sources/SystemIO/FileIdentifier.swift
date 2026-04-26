#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("unsupported platform")
#endif

struct FileIdentifier: Equatable, Hashable {
    let dev: dev_t
    let ino: ino_t
}
