import SystemIO
import Testing

@Suite enum DirectoryTests {
    @Test static func ExistenceDoesNotExist() throws {
        let path: FilePath = "Sources/SystemTests/TheLimit"
        #expect(try !path.directory.exists)
    }
    @Test static func ExistenceDoesExist() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat"
        #expect(try path.directory.exists)
    }
    @Test static func ExistenceIsSymlink() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat-link/a.txt"
        #expect(try !path.directory.exists)
    }
    @Test static func ExistenceIsSymlinkToDirectory() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat-link"
        #expect(try path.directory.exists)
    }
    @Test static func ExistenceIsNotDirectory() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat/a.txt"
        #expect(try !path.directory.exists)
    }
    @Test static func Flat() throws {
        var files: [FilePath.Component] = []

        let path: FilePath = "Sources/SystemTests/directories/flat"
        try path.directory.walk {
            files.append($1)
        } directory: {
            files.append($1)
            return .descend
        }

        #expect(files.sorted { $0.string < $1.string } == ["a.txt", "b.txt", "c.txt"])
    }

    @Test static func Complex() throws {
        var files: [FilePath.Component] = []
        let path: FilePath.Directory = "Sources/SystemTests/directories/complex"
        try path.walk {
            files.append($1)
        } directory: {
            files.append($1)
            return .descend
        }
        #expect(
            files.sorted { $0.string < $1.string } == [
                "a.txt",
                "b.txt",
                "c.txt",
                "d.txt",
                "e.txt",
                "x",
                "y",
                "z",
            ]
        )
    }

    @Test static func Shallow() throws {
        var nodes: [FilePath.Component] = []
        let path: FilePath.Directory = "Sources/SystemTests/directories/complex"
        try path.walk {
            nodes.append($1)
        } directory: {
            nodes.append($1)
            return nil
        }

        #expect(nodes.sorted { $0.string < $1.string } == ["a.txt", "b.txt", "x"])
    }

    @Test static func ShallowForLoop() throws {
        var nodes: [FilePath.Component] = []
        let path: FilePath.Directory = "Sources/SystemTests/directories/complex"
        for node: Result<FilePath.Component, FileError> in path {
            nodes.append(try node.get())
        }

        #expect(nodes.sorted { $0.string < $1.string } == ["a.txt", "b.txt", "x"])
    }

    @Test static func Cycles() throws {
        var nodes: [FilePath.Component] = []
        let path: FilePath.Directory = "Sources/SystemTests/directories/cyclical"
        try path.walk {
            nodes.append($1)
        } directory: {
            nodes.append($1)
            return .descend
        }

        #expect(nodes.sorted { $0.string < $1.string } == ["nested", "parent"])
    }
}
