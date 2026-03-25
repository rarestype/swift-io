import SystemIO
import Testing

@Suite enum EnvironmentTests {
    @Test static func ReadVariable() throws {
        #expect(Environment["SWIFT_IO_TEST_VARIABLE"] == "Hi Barbie!" as String?)
    }
    @Test static func ReadVariableUndefined() throws {
        #expect(Environment["SWIFT_IO_TEST_VARIABLEEE"] == nil)
    }
}
