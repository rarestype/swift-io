public
enum FileError:Error, Equatable, Sendable
{
    case opening(FilePath, Errno)
    case closing(FilePath, Errno)
}
extension FileError
{
    @inlinable public
    var path:FilePath
    {
        switch self
        {
        case .opening(let path, _):  path
        case .closing(let path, _):  path
        }
    }
}
extension FileError
{
    @inlinable public
    var underlying:any Error
    {
        switch self
        {
        case .opening(_, let error): error
        case .closing(_, let error): error
        }
    }
}
extension FileError:CustomStringConvertible
{
    public
    var description:String
    {
        switch self
        {
        case .opening(let path, let error):  "failed to open file '\(path)': \(error)"
        case .closing(let path, let error):  "failed to close file '\(path)': \(error)"
        }
    }
}
