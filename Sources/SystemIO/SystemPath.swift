public protocol SystemPath {
    associatedtype ComponentView: BidirectionalCollection<FilePath.Component>
    var components: ComponentView { get }
}
extension SystemPath {
    @inlinable public subscript(_: (UnboundedRange_) -> ()) -> ComponentView {
        self.components
    }
}
