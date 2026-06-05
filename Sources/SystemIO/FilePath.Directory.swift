internal import SystemPackage
internal import SystemCalls

extension FilePath {
    /// `Directory` provides an interface for creating a ``DirectoryIterator``.
    /// Directory iteration is lazy; no IO takes place until the caller
    /// requests the first element, and `Directory`  (but not
    /// ``DirectoryIterator``) supports multi-pass iteration.
    @frozen public struct Directory: Equatable, Hashable, Sendable {
        public var path: FilePath

        @inlinable public init(path: FilePath) {
            self.path = path
        }
    }
}
extension FilePath.Directory: _FilePath_Directory {}
extension FilePath.Directory: SystemPath {
    @inlinable public var components: ComponentView { .init(base: self.path.components) }
    @inlinable public var parent: Self? { self.path.parent }
}
extension FilePath.Directory {
    /// Query and return the current working directory. This can potentially fail if, for
    /// example, the directory no longer exists.
    ///
    /// Querying the current working directory involves a system call and an allocation. You
    /// should save the result if the current working directory is not expected to change.
    public static var current: Self {
        get throws {
            .init(path: try SystemCall._getcwd { FilePath.init(platformString: $0) })
        }
    }
}
extension FilePath.Directory {
    /// Creates the directory, assuming the parent directory exists. Returns true if a
    /// directory was created, false if it already exists.
    @discardableResult
    public func createLeaf(
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        ) = (.rwx, .rx, .rx)
    ) throws -> Bool {
        try self.path.withPlatformString {
            let permissions: FilePermissions = .init(permissions)
            do throws(SystemCallErrorType) {
                try SystemCall._mkdir($0, permissions.rawValue)
                return true
            } catch ._EEXIST {
                return false
            } catch let error {
                throw FileError.init(type: .mkdir(self.path, error))
            }
        }
    }

    /// Creates the directory, including any implied parent directories if they do not already
    /// exist.
    @discardableResult
    public func create(
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        ) = (.rwx, .rx, .rx)
    ) throws -> Bool {
        // recursively create the parent directory if it exists and hasn’t been created yet.
        if  let parent: Self = self.parent, try !parent.exists {
            try parent.create()
        }
        return try self.createLeaf(permissions: permissions)
    }

    #if os(Linux) || os(macOS)
    /// A shorthand for creating a directory and (conditionally) cleaning it.
    public func create(clean: Bool) throws {
        if  clean {
            try self.remove()
        }

        try self.create()
    }

    public func remove() throws {
        try SystemProcess.init(command: "rm", "-rf", "\(self)")()
    }

    public func move(into location: FilePath.Directory) throws {
        try SystemProcess.init(command: "mv", "\(self)", "\(location)/.")()
    }
    public func move(replacing destination: FilePath.Directory) throws {
        try SystemProcess.init(command: "mv", "-f", "\(self)", "\(destination)")()
    }
    #endif

    /// Returns true if a directory exists at ``path``, returns false if
    /// the file does not exist or is not a directory. To get the ``FileStatus``, call it via
    /// ``path``.
    ///
    /// This method follows symlinks.
    @inlinable public var exists: Bool {
        get throws { try self.path.status?.is(.directory) ?? false }
    }
}
extension FilePath.Directory {
    @inlinable public static func /= (
        self: inout Self,
        next: some Collection<FilePath.Component>
    ) {
        self.path.append(next)
    }

    @inlinable public static func /= (self: inout Self, next: FilePath.Component) {
        self.path.append(next)
    }
    @inlinable public static func /= (self: inout Self, next: String) {
        self.path.append(next)
    }
}
extension FilePath.Directory {
    @_disfavoredOverload
    @inlinable public static func / (self: consuming Self, next: ComponentView) -> Self {
        self /= next
        return self
    }

    @_disfavoredOverload
    @inlinable public static func / (self: consuming Self, next: FilePath.Component) -> Self {
        self /= next
        return self
    }

    @_disfavoredOverload
    @inlinable public static func / (self: consuming Self, next: String) -> Self {
        self /= next
        return self
    }
}
extension FilePath.Directory {
    @inlinable public static func / (
        self: consuming Self,
        next: FilePath.ComponentView
    ) -> FilePath {
        self /= next
        return self.path
    }
    @inlinable public static func / (
        self: consuming Self,
        next: FilePath.Component
    ) -> FilePath {
        self /= next
        return self.path
    }
    @inlinable public static func / (self: consuming Self, next: String) -> FilePath {
        self /= next
        return self.path
    }
}
extension FilePath.Directory: CustomStringConvertible {
    @inlinable public var description: String { "\(self.path)" }
}
extension FilePath.Directory: LosslessStringConvertible {
    @inlinable public init(_ description: String) { self.init(path: .init(description)) }
}
extension FilePath.Directory: ExpressibleByStringInterpolation {
    @inlinable public init(stringLiteral: String) { self.init(stringLiteral) }
}
extension FilePath.Directory: Sequence {
    @inlinable public func makeIterator() -> FilePath.DirectoryIterator {
        .init(iterating: self)
    }
}
extension FilePath.Directory {
    /// Recursively visits every node (including nested directories) within this directory. The
    /// yielded file paths begin with the same components as ``path``.
    @available(*, deprecated, message: "use `walk(file:directory:)` instead")
    @inlinable public func walk(with body: (FilePath) throws -> Bool) throws {
        try self.walk { _ = try body($0) } directory: { try body($0) ? .descend : nil }
    }
    /// Recursively visits every node (including nested directories) within this directory.
    ///
    /// If the closure returns `false`, descendants will not be visited.
    @available(*, deprecated, message: "use `walk(file:directory:)` instead")
    @inlinable public func walk(
        with body: (Self, FilePath.Component) throws -> Bool
    ) throws {
        try self.walk { _ = try body($0, $1) } directory: { try body($0, $1) ? .descend : nil }
    }
}
extension FilePath.Directory {
    /// Recursively visits every node (including nested directories) within this directory. The
    /// yielded file paths begin with the same components as ``path``.
    ///
    /// If the `directory` closure returns `nil`, descendants will not be visited.
    ///
    /// As the name suggests, `leaf` will be called only if the node did not look like a
    /// directory at the time of visitation. The walker calls `directory` if and only if it
    /// decided not to call `leaf`.
    ///
    /// Symlinks are automatically followed and it is guaranteed that exactly one of the two
    /// closures will be called exactly once for every node in the set of selected subtrees.
    public func walk(
        file leaf: (FilePath) throws -> (),
        directory: (FilePath) throws -> FilePath.DirectoryRecursion?,
    ) throws {
        try self.walk { try leaf($2) } directory: { try directory($2) }
    }

    /// Recursively visits every node (including nested directories) within this directory. To
    /// obtain the qualified path for each node, concatenate the second closure parameter with
    /// the first. The qualified paths are not necessarily absolute, but will always begin with
    /// the same components as ``path``.
    ///
    /// If the `directory` closure returns `nil`, descendants will not be visited.
    ///
    /// As the name suggests, `leaf` will be called only if the node did not look like a
    /// directory at the time of visitation. The walker calls `directory` if and only if it
    /// decided not to call `leaf`.
    ///
    /// Symlinks are automatically followed and it is guaranteed that exactly one of the two
    /// closures will be called exactly once for every node in the set of selected subtrees.
    public func walk(
        file leaf: (Self, FilePath.Component) throws -> (),
        directory: (Self, FilePath.Component) throws -> FilePath.DirectoryRecursion?,
    ) throws {
        try self.walk {
            _ = $2; return try leaf($0, $1)
        } directory: {
            _ = $2; return try directory($0, $1)
        }
    }

    private func walk(
        file leaf: (Self, FilePath.Component, FilePath) throws -> (),
        directory: (Self, FilePath.Component, FilePath) throws -> FilePath.DirectoryRecursion?,
    ) throws {
        let base: FileStatus = try .init(path: self.path)
        if !base.is(.directory) {
            return
        }

        //  minimize the amount of file descriptors we have open
        var visited: Set<FileIdentifier> = [base.id]
        var explore: [Self] = [self]
        while let node: Self = explore.popLast() {
            var stream: Stream = try .open(node)
            while let (next, type): (FilePath.Component, FileType?) = stream.next() {
                let status: FileStatus?
                let path: FilePath = node / next

                switch type {
                case .directory?:
                    // lazy evalution of stat
                    status = nil

                case .symlink?, nil:
                    // degrade broken symlinks to leaves
                    if  let target: FileStatus = try? .init(path: path),
                            target.is(.directory) {
                        status = target
                        break
                    }

                    try leaf(node, next, path)
                    continue

                case _?:
                    try leaf(node, next, path)
                    continue
                }

                // make sure we have not visited this location before, from a symlink
                if  case .descend? = try directory(node, next, path),
                    case (inserted: true, _) = visited.insert(
                        (try status ?? FileStatus.init(path: path)).id
                    ) {
                    explore.append(path.directory)
                }
            }
        }
    }
}
