enum SystemCallError: Error {
    case getcwd
}
extension SystemCallError: CustomStringConvertible {
    var description: String {
        switch self {
        case .getcwd: "could not get current working directory"
        }
    }
}
