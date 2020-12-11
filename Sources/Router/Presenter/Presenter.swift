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
    private var _makeRouter: (AnyView) -> AnyView
    
    public typealias RouterViewFactory = (SimpleRoute<Void, AnyView, VoidObservableObject>) -> AnyView
    
    public init<Parent: View, Destination: View>(parent: Parent, destination: Destination, makeRouter: @escaping RouterViewFactory) {
        self._parent = AnyView(parent)
        self._destination = AnyView(destination)
        _makeRouter = { wrappedView in
            let route = SimpleRoute {
                AnyView(wrappedView)
            }
            
            return makeRouter(route)
        }
    }
    
    init(parent: AnyView, destination: AnyView, makeRouter: @escaping RouterViewFactory) {
        self._parent = parent
        self._destination = destination
        _makeRouter = { wrappedView in
            let route = SimpleRoute {
                AnyView(wrappedView)
            }
            
            return makeRouter(route)
        }
    }
    
    public var parent: some View { _parent }
    public var destination: some View { _destination }
    
    public func makeRouter<NestedView: View>(wrapping route: NestedView) -> some View {
        _makeRouter(AnyView(route))
    }
}

@available(iOS 13, macOS 10.15, *)
public struct DestinationPresenter: Presenter {
    public let replacesParent = false
    
    public init() {}
    
    public func body(with context: PresentationContext) -> some View {
        context.destination
    }
}

@available(iOS 13, macOS 10.15, *)
public struct SheetPresenter: Presenter {
    public let replacesParent = true
    
    let providesRouter: Bool
    
    public init(providesRouter: Bool = true) {
        self.providesRouter = providesRouter
    }
    
    @ViewBuilder
    public func body(with context: PresentationContext) -> some View {
        context.parent.sheet(isPresented: .constant(true)) {
            if providesRouter {
                context.makeRouter(wrapping: context.destination)
            } else {
                context.destination
            }
        }
    }
}

@available(iOS 13, macOS 10.15, *)
public struct AnyPresenter: Presenter {
    private var _replacesParent: () -> Bool
    private var _body: (PresentationContext) -> AnyView
    
    public init<P: Presenter>(_ presenter: P) {
        self._replacesParent = { presenter.replacesParent }
        self._body = { AnyView(presenter.body(with: $0)) }
    }
    
    public func body(with context: PresentationContext) -> AnyView {
        _body(context)
    }
    
    public var replacesParent: Bool { _replacesParent() }
}
