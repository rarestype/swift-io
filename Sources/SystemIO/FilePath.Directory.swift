#if canImport(Darwin)

import func Darwin.free
import func Darwin.getcwd

#elseif canImport(Glibc)

import func Glibc.free
import func Glibc.getcwd

#else
#error("unsupported platform")
#endif

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
extension FilePath.Directory {
    public static func current() -> Self? {
        guard
        let buffer: UnsafeMutablePointer<CChar> = getcwd(nil, 0) else {
            return nil
        }
        defer {
            free(buffer)
        }

        return .init(path: FilePath.init(platformString: buffer))
    }
}
extension FilePath.Directory {
    /// A shorthand for creating a directory and (conditionally) cleaning it.
    public func create(clean: Bool) throws {
        if  clean {
            try self.remove()
        }

        try self.create()
    }
    /// Creates the directory, including any implied parent directories if they do not already
    /// exist.
    public func create() throws {
        try SystemProcess.init(command: "mkdir", "-p", "\(self.path)")()
    }

    public func remove() throws {
        try SystemProcess.init(command: "rm", "-rf", "\(self.path)")()
    }

    public func move(into location: FilePath.Directory) throws {
        try SystemProcess.init(command: "mv", "\(self.path)", "\(location.path)/.")()
    }
    public func move(replacing destination: FilePath.Directory) throws {
        try SystemProcess.init(command: "mv", "-f", "\(self.path)", "\(destination.path)")()
    }

    /// Returns true if a directory exists at ``path``, returns false if
    /// the file does not exist or is not a directory. This method follows symlinks.
    public func exists() -> Bool {
        if  let status: FileStatus = try? .status(of: self.path) {
            status.is(.directory)
        } else {
            false
        }
    }
}
extension FilePath.Directory {
    @inlinable public static func /= (self: inout Self, next: FilePath.Component) {
        self.path.append(next)
    }
    @inlinable public static func /= (self: inout Self, next: String) {
        self.path.append(next)
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
    /// decided not to call `leaf`. Symlinks are automatically followed.
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
    /// decided not to call `leaf`. Symlinks are automatically followed.
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
        let base: FileStatus = try .status(of: self.path)
        if !base.is(.directory) {
            return
        }

        //  minimize the amount of file descriptors we have open
        var visited: Set<FileIdentifier> = [base.id]
        var explore: [Self] = [self]
        while let node: Self = explore.popLast() {
            var stream: Stream = try .open(node)
            while let (next, type): (FilePath.Component, FileType?) = stream.next() {
                let status: FileStatus
                let path: FilePath = node / next

                switch type {
                case .directory?:
                    status = try .status(of: path)

                case .symlink?:
                    let target: FileStatus = try .status(of: path)
                    if  target.is(.directory) {
                        status = target
                        break
                    }

                    try leaf(node, next, path)
                    continue

                default:
                    try leaf(node, next, path)
                    continue
                }

                // make sure we have not visited this location before, from a symlink
                if  case (inserted: true, _) = visited.insert(status.id),
                    case .descend? = try directory(node, next, path) {
                    explore.append(path.directory)
                }
            }
        }
    }
}
