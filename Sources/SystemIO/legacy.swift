/// this type is a temporary API compatibility shim, do not reference it directly or conform
/// your own types to it.
public protocol _FilePath_Directory {
    init(path: FilePath)
}
extension _FilePath_Directory where Self == FilePath.Directory {
    @available(*, deprecated, message: "use throwing 'current { get }' instead")
    public static func current() -> Self? { try? .current }
}
