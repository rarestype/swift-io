#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#else
#error("unsupported platform")
#endif

extension SystemProcess {
    @frozen public struct EnvironmentSpecification: Sendable {
        @usableFromInline let buffer: [UInt8]
        @usableFromInline let offsets: [Int]
        @usableFromInline var inherit: Bool

        @inlinable init(
            inherit: Bool,
            offsets: [Int] = [],
            buffer: [UInt8] = [],
        ) {
            self.buffer = buffer
            self.offsets = offsets
            self.inherit = inherit
        }
    }
}
extension SystemProcess.EnvironmentSpecification {
    @inlinable public static var inherit: Self { .init(inherit: true) }

    @inlinable public static func inherit(
        adding encode: (inout SystemProcess.EnvironmentEncoder) throws -> Void
    ) rethrows -> Self {
        var encoder: SystemProcess.EnvironmentEncoder = .init()
        try encode(&encoder)
        return .init(inherit: true, offsets: encoder.offsets, buffer: encoder.buffer)
    }
}
extension SystemProcess.EnvironmentSpecification {
    func withUnsafePointers<T>(
        _ yield: (UnsafePointer<UnsafeMutablePointer<CChar>?>?) throws -> T
    ) rethrows -> T {
        try self.buffer.withUnsafeBytes {
            guard
            let base: UnsafePointer<CChar> = $0.bindMemory(
                to: CChar.self
            ).baseAddress else {
                return try yield(self.inherit ? environ : nil)
            }

            var inherited: Int = 0
            while case _? = environ[inherited] {
                inherited += 1
            }

            return try withUnsafeTemporaryAllocation(
                of: UnsafeMutablePointer<CChar>?.self,
                capacity: self.offsets.count + inherited + 1
            ) {
                for i: Int in 0 ..< inherited {
                    $0.initializeElement(at: i, to: environ[i])
                }
                var i: Int = inherited
                for j: Int in self.offsets {
                    /// the mutabilty is a historical quirk, from the POSIX specificatin:
                    /// '''
                    /// The statement about argv[] and envp[] being constants is included to
                    /// make explicit to future writers of language bindings that these objects
                    /// are completely constant. [...] The functions shall not modify the
                    /// strings to which the arguments point.
                    /// '''
                    let string: UnsafeMutablePointer<CChar> = .init(mutating: base + j)
                    $0.initializeElement(at: i, to: string)
                    i += 1
                }

                $0.initializeElement(at: i, to: nil)

                return try yield($0.baseAddress)
            }
        }
    }
}
