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
        context.parent.sheet(isPresented: context.$isPresented) {
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
