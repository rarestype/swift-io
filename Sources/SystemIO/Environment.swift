#if canImport(Darwin)
public import Darwin
#elseif canImport(Glibc)
public import Glibc
#elseif canImport(Musl)
public import Musl
#endif

@frozen public enum Environment {}
extension Environment {
    @inlinable public static subscript(_ name: String, overwrite: Bool = true) -> Variable {
        .init(name: name, overwrite: overwrite)
    }

    @inlinable public static subscript(_ name: String) -> String? {
        if  let cString: UnsafeMutablePointer<CChar> = getenv(name) {
            return String.init(cString: cString)
        } else {
            return nil
        }
    }

    @inlinable public static subscript(_ name: String) -> String {
        get throws(VariableGetterError<String>) {
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
        get throws(VariableGetterError<T>) {
            guard let value: String = self[name] else {
                throw .undefined(name)
            }
            guard let value: T = .init(value) else {
                throw .malformed(name, value: value)
            }
            return value
        }
    }
}
