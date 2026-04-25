import SystemIO
import Testing

@Suite enum DirectoryTests {
    @Test static func ExistenceDoesNotExist() throws {
        let path: FilePath = "Sources/SystemTests/TheLimit"
        #expect(!path.directory.exists())
    }
    @Test static func ExistenceDoesExist() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat"
        #expect(path.directory.exists())
    }
    @Test static func ExistenceIsSymlink() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat-link/a.txt"
        #expect(!path.directory.exists())
    }
    @Test static func ExistenceIsSymlinkToDirectory() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat-link"
        #expect(path.directory.exists())
    }
    @Test static func ExistenceIsNotDirectory() throws {
        let path: FilePath = "Sources/SystemTests/directories/flat/a.txt"
        #expect(!path.directory.exists())
    }
    @Test static func Flat() throws {
        var files: [FilePath] = []

        let path: FilePath = "Sources/SystemTests/directories/flat"
        try path.directory.walk {
            files.append($0)
            return .descend
        }
        let discovered: Set<FilePath.Component> = files.reduce(into: []) {
            if  let file: FilePath.Component = $1.lastComponent {
                $0.insert(file)
            }
        }

        #expect(discovered == ["a.txt", "b.txt", "c.txt"])
    }

    @Test static func Complex() throws {
        var files: [FilePath] = []

        let path: FilePath.Directory = "Sources/SystemTests/directories/complex"
        try path.walk {
            files.append($0)
            return .descend
        }

        let discovered: Set<FilePath.Component> = files.reduce(into: []) {
            if  let file: FilePath.Component = $1.lastComponent {
                $0.insert(file)
            }
        }

        #expect(
            discovered == [
                "a.txt",
                "b.txt",
                "x",
                "c.txt",
                "y",
                "d.txt",
                "z",
                "e.txt"
            ]
        )
    }

    @Test static func Shallow() throws {
        var nodes: [FilePath.Component] = []
        let path: FilePath.Directory = "Sources/SystemTests/directories/complex"
        try path.walk {
            nodes.append($1)
            return nil
        }

        #expect(
            nodes == [
                "a.txt",
                "b.txt",
                "x",
            ]
        )
    }

    @Test static func ShallowForLoop() throws {
        var nodes: [FilePath.Component] = []
        let path: FilePath.Directory = "Sources/SystemTests/directories/complex"
        for node: Result<FilePath.Component, FileError> in path {
            nodes.append(try node.get())
        }

        #expect(
            nodes == [
                "a.txt",
                "b.txt",
                "x",
            ]
        )
    }
}
