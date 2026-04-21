enum SystemRuntimeError: Error {
    case unsupportedDispatchSource
}
extension SystemRuntimeError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unsupportedDispatchSource:
            "unsupported DispatchSource"
        }
    }
}
