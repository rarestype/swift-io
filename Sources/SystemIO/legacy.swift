/// this type is a temporary API compatibility shim, do not reference it directly or conform
/// your own types to it.
public protocol _FilePath_Directory {
    init(path: FilePath)
}
extension _FilePath_Directory where Self == FilePath.Directory {
    @available(*, deprecated, message: "use throwing 'current { get }' instead")
    public static func current() -> Self? { try? .current }

    /// Returns true if a directory exists at ``path``, returns false if
    /// the file does not exist or is not a directory. This method follows symlinks.
    @available(*, deprecated, message: "use throwing 'exists { get }' instead")
    public func exists() -> Bool {
        if  let status: FileStatus = try? .status(of: self.path) {
            status.is(.directory)
        } else {
            false
        }
    }
}
