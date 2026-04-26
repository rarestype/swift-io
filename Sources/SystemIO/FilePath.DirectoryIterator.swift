extension FilePath {
    /// A safe abstraction for iterating directory entries from a directory pointer.
    /// Instances of this type always close their streams on deinit.
    public final class DirectoryIterator {
        private var stream: Directory.Stream
        private var source: Directory?

        public init(iterating source: FilePath.Directory) {
            self.source = source
            self.stream = .empty
        }
    }
}
extension FilePath.DirectoryIterator: IteratorProtocol {
    public func next() -> Result<FilePath.Component, FileError>? {
        setup: do {
            guard let source: FilePath.Directory = self.source else {
                break setup
            }

            self.source = nil
            self.stream = try .open(source)
        } catch {
            return .failure(error)
        }

        guard let (component, _): (FilePath.Component, FileType?) = self.stream.next() else {
            return nil
        }

        return .success(component)
    }
}
