#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

extension Environment {
    @frozen public struct Variable {
        @usableFromInline let name: String
        @usableFromInline let overwrite: Bool

        @inlinable init(name: String, overwrite: Bool) {
            self.name = name
            self.overwrite = overwrite
        }
    }
}
extension Environment.Variable {
    public static func &= (self: Self, value: String?) throws(Environment.VariableSetterError) {
        if  let value: String {
            guard case 0 = setenv(self.name, value, self.overwrite ? 1 : 0) else {
                throw .malformed(self.name, value: value)
            }
        } else {
            unsetenv(self.name)
        }
    }

    @inlinable public static func &= (
        self: Self,
        value: (some CustomStringConvertible)?
    ) throws(Environment.VariableSetterError) {
        try self &= value.map { "\($0)" }
    }
}
