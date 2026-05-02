import SystemIO
import Testing

@Suite enum EnvironmentTests {
    @Test static func ReadVariable() throws {
        let value: String = "Hi Barbie!"
        try Environment["SWIFT_IO_TEST_VARIABLE"] &= value
        #expect(Environment["SWIFT_IO_TEST_VARIABLE"] == value as String?)
    }
    @Test static func ReadVariableUndefined() throws {
        #expect(Environment["SWIFT_IO_TEST_VARIABLEEE"] == nil)
    }
}
