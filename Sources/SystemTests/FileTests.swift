import SystemIO
import Testing

@Suite enum FileTests {
    @Test static func Read() throws {
        let file: FilePath = "Sources/SystemTests/files/a.txt"
        let text: String = try file.read()
        #expect(text == "Hi Barbie!\n")
    }
}
