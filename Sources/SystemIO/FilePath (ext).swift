import struct SystemPackage.Errno
@_exported import struct SystemPackage.FilePath

extension FilePath {
    @inlinable public var directory: Directory { .init(path: self) }
}
extension FilePath {
    /// Returns the status of the file, or nil if it does not exist or if any interior path
    /// components do not exist.
    ///
    /// This method follows symlinks.
    public var status: FileStatus? {
        get throws {
            do {
                return try .init(path: self)
            } catch .noSuchFileOrDirectory {
                // when file does not exist
                return nil
            } catch .notDirectory {
                // when interior path component is not a directory
                return nil
            }
        }
    }
    /// Returns true if a file exists here, false if a file does not exist.
    /// This method follows symlinks.
    @inlinable public var exists: Bool {
        get throws { try self.status != nil }
    }
}
extension FilePath {
    @inlinable func open(
        _ mode: FileDescriptor.AccessMode,
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        )?,
        options: FileDescriptor.OpenOptions
    ) throws -> FileDescriptor {
        do {
            return try .open(
                self, mode,
                options: options,
                permissions: permissions.map(FilePermissions.init(_:))
            )
        } catch let errno as Errno {
            throw FileError.init(type: .opening(self, errno))
        }
    }

    @inlinable func close(_ file: FileDescriptor) throws {
        do {
            try file.close()
        } catch let errno as Errno {
            throw FileError.init(type: .closing(self, errno))
        }
    }
}
extension FilePath {
    @inlinable public func open<T>(
        _ mode: FileDescriptor.AccessMode,
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        )? = nil,
        options: FileDescriptor.OpenOptions = [],
        with body: (FileDescriptor) throws -> T
    ) throws -> T {
        let file: FileDescriptor = try self.open(
            mode,
            permissions: permissions,
            options: options
        )

        let success: T
        do {
            success = try body(file)
        } catch let error {
            //  If the closure throws, we still need to close the file.
            //  But we do not care about any additional errors from that.
            try? file.close()
            throw error
        }

        try self.close(file)
        return success
    }

    @inlinable public func open<T>(
        _ mode: FileDescriptor.AccessMode,
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        )? = nil,
        options: FileDescriptor.OpenOptions = [],
        with body: (FileDescriptor) async throws -> T
    ) async throws -> T {
        let file: FileDescriptor = try self.open(
            mode,
            permissions: permissions,
            options: options
        )

        let success: T
        do {
            success = try await body(file)
        } catch let error {
            try? file.close()
            throw error
        }

        try self.close(file)
        return success
    }
}
extension FilePath {
    /// Reads a *single* line from this file, without the line terminator.
    ///
    /// This is mostly useful for reading secrets, like keys and tokens. This is not performant
    /// for large files, for that, use
    /// ``readLines(buffering:with:) (Int, (Substring)->Void) -> ()`` instead.
    @inlinable public func readLine() throws -> String {
        .init(try self.read().prefix { !$0.isNewline })
    }

    /// Reads a file line-by-line incrementally, yielding each line as an `ArraySlice<UInt8>`.
    @inlinable public func readLines(
        buffering: Int = 0x100000,
        with body: (ArraySlice<UInt8>) throws -> Void
    ) throws {
        try self.open(.readOnly) { try $0.readLines(buffering: buffering, with: body) }
    }
    /// Reads a file line-by-line incrementally, yielding each line as a ``Substring``.
    @inlinable public func readLines(
        buffering: Int = 0x100000,
        with body: (Substring) throws -> Void
    ) throws {
        try self.open(.readOnly) { try $0.readLines(buffering: buffering, with: body) }
    }

    @inlinable public func read(_: [UInt8].Type = [UInt8].self) throws -> [UInt8] {
        try self.open(.readOnly) { try $0.read(buffering: 0x20000) }
    }
    @inlinable public func read(_: String.Type = String.self) throws -> String {
        try self.open(.readOnly) { try $0.read(buffering: 0x20000) }
    }
}
extension FilePath {
    @inlinable public func overwrite(
        with bytes: ArraySlice<UInt8>,
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        ) = (.rw, .rw, .r)
    ) throws {
        let _: Int = try self.open(
            .writeOnly,
            permissions: permissions,
            options: [.create, .truncate]
        ) {
            try $0.writeAll(bytes)
        }
    }

    @inlinable public func overwrite(
        with utf8: String.UTF8View,
        permissions: (
            owner: FilePermissions.Component?,
            group: FilePermissions.Component?,
            other: FilePermissions.Component?
        ) = (.rw, .rw, .r)
    ) throws {
        let _: Int = try self.open(
            .writeOnly,
            permissions: permissions,
            options: [.create, .truncate]
        ) {
            try $0.writeAll(utf8)
        }
    }
}
