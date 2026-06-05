internal import SystemCalls

enum FileErrorType: Error, Equatable, Sendable {
    case opening(FilePath, SystemCallErrorType)
    case closing(FilePath, SystemCallErrorType)
    case seek(Seek)
    case read(Read)
    case remove(FilePath, SystemCallErrorType)
    case mkdir(FilePath, SystemCallErrorType)
}
