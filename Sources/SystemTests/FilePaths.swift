import SystemIO
import Testing

@Suite enum FilePaths {
    @Test static func ResolveRelative() throws {
        let path: FilePath = "foo/bar/baz"
        let base: FilePath = "foo/bar"
        #expect(path.relative(to: base).elementsEqual(["baz"]))
    }
    @Test static func ResolveRelativeMultipleLevels() throws {
        let path: FilePath = "foo/bar/baz/a.xyz"
        let base: FilePath = "foo/bar"
        #expect(path.relative(to: base).elementsEqual(["baz", "a.xyz"]))
    }
    @Test static func ResolveExternal() throws {
        let path: FilePath = "foo/a.xyz"
        let base: FilePath = "foo/bar"
        #expect(path.relative(to: base).elementsEqual(["..", "a.xyz"]))
    }
    @Test static func ResolveExternalMultipleLevels() throws {
        let path: FilePath = "foo/bar/baz/a.xyz"
        let base: FilePath = "foo/bar/qux"
        #expect(path.relative(to: base).elementsEqual(["..", "baz", "a.xyz"]))
    }
}
