public import SystemIO

public enum Subprocess {}
extension Subprocess {
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
        let process: (
            stdout: [UInt8],
            stderr: [UInt8],
            status: Result<(), SystemProcessError>
        ) = try await self.capture(buffering: bufferSize, command) {
            try await $0.reduce(into: [], +=)
        } stderr: {
            try await $0.reduce(into: [], +=)
        }

        switch process.status {
        case .failure(.exit(let code, let invocation)):
            throw SubprocessError.init(
                invocation: invocation,
                status: code,
                stderr: process.stderr
            )

        case .failure(let error):
            throw error

        case .success:
            return (process.stdout, process.stderr)
        }
    }

    private static func capture<F1, F2>(
        buffering bufferSize: Int = 8192,
        _ command: (
            (),
            _ stdout: FileDescriptor,
            _ stderr: FileDescriptor
        ) throws -> SystemProcess,
        stdout: sending (consuming AsyncThrowingStream<[UInt8], any Error>) async throws -> F1,
        stderr: sending (consuming AsyncThrowingStream<[UInt8], any Error>) async throws -> F2,
    ) async throws -> (stdout: F1, stderr: F2, status: Result<(), SystemProcessError>) {
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

        async let stdout: F1 = stdout(readable.stdout.read(buffering: bufferSize))
        async let stderr: F2 = stderr(readable.stderr.read(buffering: bufferSize))

        let complete: (stdout: F1, stderr: F2) = (try await stdout, try await stderr)
        // now that the pipes have hit EOF (which happens when the child closes them
        // upon exiting), we can safely call `waitpid`. The child is almost certainly dead
        // already, so this synchronous call will return almost instantly without
        // blocking the thread pool
        return (complete.stdout, complete.stderr, process.status())
    }
}
