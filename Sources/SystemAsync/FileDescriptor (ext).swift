#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#else
#error("unsupported platform")
#endif

internal import Dispatch
internal import SystemIO
internal import SystemPackage

extension FileDescriptor {
    /// Reads all data from a non-blocking file descriptor asynchronously using Dispatch.
    func readAll(
        buffering bufferSize: Int = 8192
    ) async throws -> [UInt8] {
        try await self.read(buffering: bufferSize).reduce(into: [], +=)
    }

    func read(
        buffering bufferSize: Int = 8192
    ) throws -> AsyncThrowingStream<[UInt8], any Error> {
        try self.setNonBlocking()

        let queue: DispatchQueue = .init(
            label: "FileDescriptor.read(buffering: \(bufferSize)) (fd = \(self.rawValue))"
        )
        let source: any DispatchSourceRead = DispatchSource.makeReadSource(
            fileDescriptor: self.rawValue,
            queue: queue
        )

        guard case let source as DispatchSource = source else {
            throw SystemRuntimeError.unsupportedDispatchSource
        }

        return .init { (
                output: AsyncThrowingStream<[UInt8], any Error>.Continuation
            ) in

            output.onTermination = { @Sendable _ in
                source.cancel()
            }

            source.setEventHandler {
                let buffer: UnsafeMutableRawBufferPointer = .allocate(
                    byteCount: bufferSize,
                    alignment: 1
                )
                defer {
                    buffer.deallocate()
                }
                do {
                    // Loop to drain all currently available bytes until we hit EAGAIN
                    while true {
                        let bytesRead: Int = try self.read(into: buffer)
                        if  bytesRead == 0 {
                            // EOF: The write end was closed
                            output.finish()
                            source.cancel()
                            return
                        }

                        // Yield the chunk of bytes to the async context
                        output.yield([UInt8].init(buffer[..<bytesRead]))
                    }
                    // EAGAIN/EWOULDBLOCK: We drained the pipe for now.
                    // Do nothing and let the DispatchSource wait for the next event.
                } catch Errno.wouldBlock, Errno.resourceTemporarilyUnavailable {
                } catch {
                    // A real error occurred
                    output.finish(throwing: error)
                    source.cancel()
                }
            }
            // Start listening for events
            source.resume()
        }
    }
}
extension FileDescriptor {
    func setNonBlocking() throws {
        let flags: Int32 = fcntl(self.rawValue, F_GETFL, 0)
        if  flags == -1 {
            throw FileControlError.getFlags
        }

        let result: Int32 = fcntl(self.rawValue, F_SETFL, flags | O_NONBLOCK)
        if  result == -1 {
            throw FileControlError.setFlags
        }
    }
}
