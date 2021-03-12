import SwiftUI

@available(iOS 13, macOS 10.15, *)
public protocol Presenter {
    associatedtype Body: View
    var presentationMode: RoutePresentationMode { get }
    
    func body(with context: PresentationContext) -> Body
}

public enum RoutePresentationMode {
    case normal
    case replaceParent
    case sibling
}

@available(iOS 13, macOS 10.15, *)
public struct PresentationContext {
    private var _parent: AnyView
    private var _destination: AnyView
    private var _makeDestinationRouter: (PresentationContext) -> AnyView
    
    public typealias RouterViewFactory = (PresentationContext) -> AnyView
    
    public init<Parent: View, Destination: View>(parent: Parent, destination: Destination, isPresented: Binding<Bool>, makeRouter: @escaping RouterViewFactory) {
        self._parent = AnyView(parent)
        self._destination = AnyView(destination)
        self._isPresented = isPresented
        _makeDestinationRouter = { `self` in
            return makeRouter(self)
        }
    }
    
    init(parent: AnyView, destination: AnyView, isPresented: Binding<Bool>, makeRouter: @escaping RouterViewFactory) {
        self._parent = parent
        self._destination = destination
        self._isPresented = isPresented
        _makeDestinationRouter = { `self` in
            return makeRouter(self)
        }
    }
    
    public var parent: some View { _parent }
    public var destination: some View { _destination }
    @Binding public var isPresented: Bool
    
    public func makeDestinationRouter() -> some View {
        _makeDestinationRouter(self)
    }
}
