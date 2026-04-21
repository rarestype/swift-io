import Testing
import SystemIO
import SystemAsync

@Suite struct SystemAsyncTests {
    @Test static func Capture() async throws {
        let process: (stdout: String, stderr: String) = try await SystemProcess.capture {
            try SystemProcess.init(
                command: "/bin/sh",
                arguments: ["-c", "echo 'hello'; echo 'error' >&2"],
                stdout: $1,
                stderr: $2,
            )
        }

        #expect(process.stdout == "hello\n")
        #expect(process.stderr == "error\n")
    }
}
