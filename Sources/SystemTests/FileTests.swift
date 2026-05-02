import SystemIO
import Testing

@Suite enum FileTests {
    @Test static func StatusDoesNotExistLeaf() throws {
        let path: FilePath = "Sources/SystemTests/TheLimit"
        #expect(try nil == path.status)
    }
    @Test static func StatusDoesNotExist() throws {
        let path: FilePath = "Sources/SystemTests/files/a.txt/b.txt"
        #expect(try nil == path.status)
    }
    @Test static func StatusDoesExist() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat/a.txt"
        #expect(try path.status?.type == .regular)
    }
    @Test static func StatusDoesExistDirectory() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat"
        #expect(try path.status?.type == .directory)
    }
    @Test static func StatusIsSymlink() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat-link/a.txt"
        #expect(try path.status?.type == .regular)
    }
    @Test static func StatusIsSymlinkToDirectory() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat-link"
        #expect(try path.status?.type == .directory)
    }
    @Test static func Read() throws {
        let file: FilePath = "Sources/SystemTests/files/a.txt"
        let text: String = try file.read()
        #expect(text == "Hi Barbie!\n")
    }
}
