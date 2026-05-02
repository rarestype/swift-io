extension Environment {
    @frozen public enum VariableSetterError: Error {
        case malformed(String, value: String)
    }
}
extension Environment.VariableSetterError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .malformed(let name, value: let value):
            """
            Environment variable '\(name)' cannot be set to value '\(value)'
            """
        }
    }
}
