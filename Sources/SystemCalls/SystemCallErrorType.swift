#if canImport(Darwin)

public import Darwin

#elseif canImport(Glibc)

public import Glibc

#elseif canImport(WASILibc)

public import WASILibc

#else
#error("unsupported platform")
#endif

@frozen public struct SystemCallErrorType: Error, Equatable, Sendable {
    @usableFromInline let errno: Int32
    @inlinable public init(errno: Int32) {
        self.errno = errno
    }
}
extension SystemCallErrorType {
    @inlinable public static var _EEXIST: Self { .init(errno: EEXIST) }
    @inlinable public static var _ENOTDIR: Self { .init(errno: ENOTDIR) }
    @inlinable public static var _ENOTEMPTY: Self { .init(errno: ENOTEMPTY) }
    @inlinable public static var _ENOENT: Self { .init(errno: ENOENT) }
}
extension SystemCallErrorType: CustomStringConvertible {
    public var description: String {
        guard let cString: UnsafeMutablePointer<CChar> = strerror(self.errno) else {
            return "unknown error"
        }
        return String.init(cString: cString)
    }
}
