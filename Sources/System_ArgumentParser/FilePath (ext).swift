import ArgumentParser
import SystemIO

extension FilePath:@retroactive ExpressibleByArgument
{
    @inlinable public
    init?(argument:String) { self.init(argument) }
}
