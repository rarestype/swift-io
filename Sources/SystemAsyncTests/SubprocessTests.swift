import Testing
import SystemIO
import SystemAsync

@Suite struct SubprocessTests {
    @Test static func Capture() async throws {
        let process: (stdout: String, stderr: String) = try await Subprocess.capture {
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

    @Test static func WorkingDirectory() async throws {
        let process: (stdout: String, stderr: String) = try await Subprocess.capture {
            try SystemProcess.init(
                command: "ls",
                arguments: [],
                in: "Sources" / "SystemTests" / "files",
                stdout: $1,
                stderr: $2,
            )
        }

        #expect(process.stdout == "a.txt\n")
    }
}
