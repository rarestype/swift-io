public struct FileError: Error, Equatable, Sendable {
    let type: FileErrorType

    init(type: FileErrorType) {
        self.type = type
    }
}
extension FileError {
    public var path: FilePath? {
        switch self.type {
        case .opening(let path, _): path
        case .closing(let path, _): path
        case .seek: nil
        case .read: nil
        case .remove(let path, _): path
        case .mkdir(let path, _): path
        }
    }
}
extension FileError: CustomStringConvertible {
    public var description: String {
        switch self.type {
        case .opening(let path, let error): "failed to open file '\(path)': \(error)"
        case .closing(let path, let error): "failed to close file '\(path)': \(error)"
        case .seek(let seek): "file seek error: \(seek)"
        case .read(let read): "file read error: \(read)"
        case .remove(let path, let error): "failed to remove file '\(path)': \(error)"
        case .mkdir(let path, let error): "failed to create directory '\(path)': \(error)"
        }
    }
}
