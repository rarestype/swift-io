public import SystemIO

extension SystemProcess {
    public static func capture(
        buffering bufferSize: Int = 8192,
        _ command: (
            (),
            _ stdout: FileDescriptor,
            _ stderr: FileDescriptor
        ) throws -> SystemProcess,
    ) async throws -> (
        stdout: String,
        stderr: String
    ) {
        let process: (
            stdout: [UInt8],
            stderr: [UInt8]
        ) = try await Self.capture(buffering: bufferSize, command)
        return (
            String.init(decoding: process.stdout, as: UTF8.self),
            String.init(decoding: process.stderr, as: UTF8.self)
        )
    }

    public static func capture(
        buffering bufferSize: Int = 8192,
        _ command: (
            (),
            _ stdout: FileDescriptor,
            _ stderr: FileDescriptor
        ) throws -> SystemProcess,
    ) async throws -> (
        stdout: [UInt8],
        stderr: [UInt8]
    ) {
        let readable: (stdout: FileDescriptor, stderr: FileDescriptor)
        let writable: (stdout: FileDescriptor, stderr: FileDescriptor)

        (readEnd: readable.stdout, writable.stdout) = try FileDescriptor.pipe()
        (readEnd: readable.stderr, writable.stderr) = try FileDescriptor.pipe()

        defer {
            try? readable.stdout.close()
            try? readable.stderr.close()
        }

        let process: SystemProcess
        do {
            // Close the parent’s write end of the pipe so EOF can be reached
            defer {
                try? writable.stdout.close()
                try? writable.stderr.close()
            }
            process = try command((), writable.stdout, writable.stderr)
        }

        async let stdout: [UInt8] = readable.stdout.readAll(buffering: bufferSize)
        async let stderr: [UInt8] = readable.stderr.readAll(buffering: bufferSize)

        try process()

        return (try await stdout, try await stderr)
    }
}
