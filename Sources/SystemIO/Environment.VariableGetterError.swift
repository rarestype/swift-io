extension Environment {
    @available(*, deprecated, renamed: "VariableGetterError")
    public typealias VariableError = VariableGetterError
}
extension Environment {
    @frozen public enum VariableGetterError<T>: Error {
        case undefined(String)
        case malformed(String, value: String)
    }
}
extension Environment.VariableGetterError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .undefined(let name):
            "environment variable '\(name)' is not defined"
        case .malformed(let name, value: let value):
            """
            Environment variable '\(name)' (with value '\(value)') does not encode a \
            valid instance of '\(String.init(reflecting: T.self))'
            """
        }
    }
}
