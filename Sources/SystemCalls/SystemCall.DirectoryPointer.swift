#if canImport(Darwin)

public import Darwin

#endif

extension SystemCall {
    #if canImport(Darwin)
    public typealias DirectoryPointer = UnsafeMutablePointer<DIR>
    #else
    public typealias DirectoryPointer = OpaquePointer
    #endif
}
