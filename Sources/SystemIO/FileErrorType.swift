import SystemPackage

@usableFromInline enum FileErrorType: Error, Equatable, Sendable {
    case opening(FilePath, Errno)
    case closing(FilePath, Errno)
    case seek(Seek)
    case read(Read)
}
