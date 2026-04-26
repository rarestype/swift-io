extension FileErrorType {
    @usableFromInline enum Read: Error, Equatable, Sendable {
        case incomplete(read: Int, of: Int)
    }
}
extension FileErrorType.Read: CustomStringConvertible {
    @usableFromInline var description: String {
        switch self {
        case .incomplete(read: let bytes, of: let expected):
            "could only read \(bytes) of \(expected) bytes"
        }
    }
}
