@frozen public struct SystemCallError: Error {
    public let type: SystemCallErrorType
    public let call: SystemCallIdentifier

    @inlinable init(type: SystemCallErrorType, call: SystemCallIdentifier) {
        self.type = type
        self.call = call
    }
}
extension SystemCallError: CustomStringConvertible {
    public var description: String {
        switch self.call {
        case .getcwd: "could not get current working directory: \(self.type)"
        }
    }
}
