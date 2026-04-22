@_exported import struct SystemPackage.FileDescriptor

extension FileDescriptor {
    @inlinable public func length() throws -> Int {
        let count: Int64 = try self.seek(offset: 0, from: .end)
        guard count < .max else {
            throw FileSeekError.isDirectory
        }
        return .init(count)
    }

    /// Attempts to read the entirety of this file to a string. This involves
    /// a seek operation, followed by a read operation.
    @available(
        *, deprecated, message: """
        readAll(_:) can experience race conditions and can fail to read the entire input, \
        use `read(buffering:as:)` instead
        """
    ) @inlinable public func readAll(_: String.Type = String.self) throws -> String {
        let bytes: Int = try self.length()
        return try .init(unsafeUninitializedCapacity: bytes) {
            let buffer: UnsafeMutableRawBufferPointer = .init($0)
            let read: Int = try self.read(fromAbsoluteOffset: 0, into: buffer)
            if  read != bytes {
                throw FileReadError.incomplete(read: read, of: bytes)
            } else {
                return read
            }
        }
    }

    /// Attempts to read the entirety of this file to an array of raw bytes.
    /// This involves a seek operation, followed by a read operation.
    @available(
        *, deprecated, message: """
        readAll(_:) can experience race conditions and can fail to read the entire input, \
        use `read(buffering:)` instead
        """
    ) @inlinable public func readAll(_: [UInt8].Type = [UInt8].self) throws -> [UInt8] {
        let bytes: Int = try self.length()
        return try .init(unsafeUninitializedCapacity: bytes) {
            let buffer: UnsafeMutableRawBufferPointer = .init($0)
            $1 = try self.read(fromAbsoluteOffset: 0, into: buffer)
            if  $1 != bytes {
                throw FileReadError.incomplete(read: $1, of: bytes)
            }
        }
    }

    @available(*, deprecated, renamed: "read(buffering:as:)")
    @inlinable @_disfavoredOverload public func read<Encoding>(
        _ encoding: Encoding.Type = Unicode.UTF8.self,
        buffering: Int = 4096,
    ) throws -> String where Encoding: _UnicodeEncoding, Encoding.CodeUnit == UInt8 {
        try self.read(buffering: buffering, as: encoding)
    }
}
extension FileDescriptor {
    /// Attempts to read text from this file until no more data is available.
    /// This moves the file descriptor’s offset.
    @inlinable public func read<Encoding>(
        buffering: Int = 4096,
        as encoding: Encoding.Type = Unicode.UTF8.self,
    ) throws -> String where Encoding: _UnicodeEncoding, Encoding.CodeUnit == UInt8 {
        // i cannot think of a better way to avoid the intermediate array
        .init(decoding: try self.read(buffering: buffering), as: encoding)
    }
    /// Attempts to read raw bytes from this file until no more data is available.
    /// This moves the file descriptor’s offset.
    @inlinable public func read(buffering: Int = 4096) throws -> [UInt8] {
        let buffer: UnsafeMutableRawBufferPointer = .allocate(
            byteCount: buffering,
            alignment: 1
        )
        defer {
            buffer.deallocate()
        }

        var output: [UInt8] = []

        while true {
            let bytes: Int = try self.read(into: buffer)
            if  bytes > 0 {
                output += buffer.prefix(bytes)
            } else {
                return output
            }
        }
    }

    @inlinable public func readByte<Code>(as: Code.Type = Code.self) throws -> Code?
        where Code: RawRepresentable<UInt8> {
        try self.readByte().flatMap(Code.init(rawValue:))
    }

    @inlinable public func readByte() throws -> UInt8? {
        try withUnsafeTemporaryAllocation(byteCount: 1, alignment: 1) {
            if  try self.read(into: $0) == 1 {
                return $0[0]
            } else {
                return nil
            }
        }
    }
}
extension FileDescriptor {
    /// Reads a file line-by-line incrementally, yielding each line as a `Substring`.
    public func readLines(
        buffering: Int = 0x100000,
        with body: (Substring) throws -> Void
    ) throws {
        try self.readLines(buffering: buffering) {
            let string: String = .init(decoding: $0, as: Unicode.UTF8.self)
            try body(string[...])
        }
    }
    /// Reads a file line-by-line incrementally, yielding each line as an `ArraySlice<UInt8>`.
    public func readLines(
        buffering: Int = 0x100000,
        with body: (ArraySlice<UInt8>) throws -> Void
    ) throws {
        let buffer: UnsafeMutableRawBufferPointer = .allocate(
            byteCount: buffering,
            alignment: 1
        )
        defer {
            buffer.deallocate()
        }

        var bytes: [UInt8] = []
        ;   bytes.reserveCapacity(buffering)

        while true {
            // Read directly from the file descriptor
            let read: Int = try self.read(into: buffer)
            if  read == 0 {
                // end of file
                if !bytes.isEmpty {
                    try body(bytes[...])
                }
                break
            }

            // Bind the raw buffer to UInt8 and append to our leftover array
            bytes += buffer.prefix(read)

            var i: Int = bytes.startIndex
            // Keep extracting lines as long as we find a newline byte (0x0A)
            while let newline: Int = bytes[i...].firstIndex(of: 0x0A) {
                try body(bytes[i ..< newline])
                i = bytes.index(after: newline)
            }
            if  i > 0 {
                // move remaining data to the front of the array
                bytes.removeFirst(i)
            }
        }
    }
}
extension FileDescriptor {
    @inlinable public static func <- (binding: Int32, self: Self) -> SystemProcess.Stream {
        precondition(binding > 2, "Invalid file descriptor index: \(binding)")
        return .init(parent: self, child: binding)
    }
}
