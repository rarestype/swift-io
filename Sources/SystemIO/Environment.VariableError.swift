extension Environment {
    @frozen public enum VariableError<T>: Error {
        case undefined(String)
        case malformed(String)
    }
}
extension Environment.VariableError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .undefined(let name):
            "environment variable '\(name)' is not defined"
        case .malformed(let name):
            """
            Environment variable '\(name)' does not encode a \
            valid instance of '\(String.init(reflecting: T.self))'
            """
        }
    }
}
