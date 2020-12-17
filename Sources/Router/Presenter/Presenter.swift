import SwiftUI

@available(iOS 13, macOS 10.15, *)
public protocol Presenter {
    associatedtype Body: View
    var replacesParent: Bool { get }
    
    func body(with context: PresentationContext) -> Body
}

@available(iOS 13, macOS 10.15, *)
public struct PresentationContext {
    private var _parent: AnyView
    private var _destination: AnyView
    private var _makeRouter: (AnyView, PresentationContext) -> AnyView
    
    public typealias RouterViewFactory = (SimpleRoute<Void, AnyView, VoidObservableObject>, PresentationContext) -> AnyView
    
    public init<Parent: View, Destination: View>(parent: Parent, destination: Destination, isPresented: Binding<Bool>, makeRouter: @escaping RouterViewFactory) {
        self._parent = AnyView(parent)
        self._destination = AnyView(destination)
        self._isPresented = isPresented
        _makeRouter = { wrappedView, `self` in
            let route = SimpleRoute {
                AnyView(wrappedView)
            }
            
            return makeRouter(route, self)
        }
    }
    
    init(parent: AnyView, destination: AnyView, isPresented: Binding<Bool>, makeRouter: @escaping RouterViewFactory) {
        self._parent = parent
        self._destination = destination
        self._isPresented = isPresented
        _makeRouter = { wrappedView, `self` in
            let route = SimpleRoute {
                AnyView(wrappedView)
            }
            
            return makeRouter(route, self)
        }
    }
    
    public var parent: some View { _parent }
    public var destination: some View { _destination }
    @Binding public var isPresented: Bool
    
    public func makeRouter<NestedView: View>(wrapping route: NestedView) -> some View {
        _makeRouter(AnyView(route), self)
    }
}
