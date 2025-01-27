import ArgumentParser
import SystemIO

extension FilePath.Directory:ExpressibleByArgument
{
    @inlinable public
    init?(argument:String) { self.init(argument) }
}
