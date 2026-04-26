#if canImport(Darwin)
public import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("unsupported platform")
#endif

extension FilePath {
    #if canImport(Darwin)
    typealias DirectoryPointer = UnsafeMutablePointer<DIR>
    #elseif canImport(Glibc)
    typealias DirectoryPointer = OpaquePointer
    #endif
}
