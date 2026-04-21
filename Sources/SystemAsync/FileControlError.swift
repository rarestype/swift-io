enum FileControlError: Error {
    case getFlags
    case setFlags
}
extension FileControlError: CustomStringConvertible {
    var description: String {
        switch self {
        case .getFlags:
            return "fcntl: failed to get file descriptor flags (F_GETFL)"
        case .setFlags:
            return "fcntl: failed to set file descriptor flags (F_SETFL)"
        }
    }
}
