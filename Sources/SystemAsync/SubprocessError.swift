@frozen public struct SubprocessError: Error {
    public let invocation: [String]
    public let status: Int32
    public let stderr: [UInt8]
}
extension SubprocessError: CustomStringConvertible {
    public var description: String {
        let stderr: String = String.init(decoding: stderr, as: UTF8.self)
        return """
        process \(self.invocation) exited with code: \(self.status)
        -------
        \(stderr.isEmpty ? "(stderr empty)" : stderr)
        """
    }
}
