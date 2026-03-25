#if canImport(Darwin)
public import Darwin
#elseif canImport(Glibc)
public import Glibc
#elseif canImport(Musl)
public import Musl
#endif

@frozen public enum Environment {}
extension Environment {
    @inlinable public static subscript(_ name: String) -> String? {
        if  let cString: UnsafeMutablePointer<CChar> = getenv(name) {
            return String.init(cString: cString)
        } else {
            return nil
        }
    }

    @inlinable public static subscript(_ name: String) -> String {
        get throws(VariableError<String>) {
            guard let value: String = self[name] else {
                throw .undefined(name)
            }
            return value
        }
    }

    @inlinable public static subscript<T>(
        _ name: String,
        as _: T.Type = T.self
    ) -> T where T: LosslessStringConvertible {
        get throws(VariableError<T>) {
            guard let value: String = self[name] else {
                throw .undefined(name)
            }
            guard let value: T = .init(value) else {
                throw .malformed(name)
            }
            return value
        }
    }
}
