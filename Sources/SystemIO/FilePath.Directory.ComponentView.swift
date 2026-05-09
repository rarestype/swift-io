extension FilePath.Directory {
    @frozen public struct ComponentView: Sendable {
        @usableFromInline var base: FilePath.ComponentView
        @inlinable init(base: FilePath.ComponentView) {
            self.base = base
        }
    }
}
extension FilePath.Directory.ComponentView: BidirectionalCollection {
    public typealias Index = FilePath.ComponentView.Index

    @inlinable public var startIndex: FilePath.ComponentView.Index { self.base.startIndex }
    @inlinable public var endIndex: FilePath.ComponentView.Index { self.base.endIndex }

    @inlinable public func index(
        after index: FilePath.ComponentView.Index
    ) -> FilePath.ComponentView.Index {
        self.base.index(after: index)
    }

    @inlinable public func index(
        before index: FilePath.ComponentView.Index
    ) -> FilePath.ComponentView.Index {
        self.base.index(before: index)
    }

    @inlinable public subscript(position: Index) -> FilePath.Component {
        self.base[position]
    }
}
extension FilePath.Directory.ComponentView: RangeReplaceableCollection {
    @inlinable public init() {
        self.init(base: .init())
    }

    @inlinable public mutating func replaceSubrange(
        _ destination: Range<FilePath.ComponentView.Index>,
        with elements: some Collection<FilePath.Component>
    ) {
        self.base.replaceSubrange(destination, with: elements)
    }
}
