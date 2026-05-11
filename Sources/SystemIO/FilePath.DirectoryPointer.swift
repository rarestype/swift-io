#if canImport(Darwin)
public import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#else
#error("unsupported platform")
#endif

extension FilePath {
    #if canImport(Darwin)
    typealias DirectoryPointer = UnsafeMutablePointer<DIR>
    #else
    typealias DirectoryPointer = OpaquePointer
    #endif
}
