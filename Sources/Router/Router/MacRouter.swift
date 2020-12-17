#if canImport(AppKit)
import Combine
import SwiftUI
import Router

@available(macOS 10.15, *)
fileprivate final class RouteHost: Hashable {
    
    // MARK: State
    
    let root: AnyView
    
    // MARK: Init
    
    init(root: AnyView) {
        self.root = root
    }
    
    // MARK: Equatable / hashable
    
    static func == (lhs: RouteHost, rhs: RouteHost) -> Bool {
        lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}

@available(iOS 13, macOS 10.15, *)
public final class PresenterViewModel: ObservableObject {
    @Published internal var isPresented = true
    
    internal init() {}
}

@available(iOS 13, macOS 10.15, *)
fileprivate struct PresenterView<WrappedView: View>: View {
    let wrappedView: WrappedView
    @ObservedObject var viewModel: PresenterViewModel
    
    var body: some View {
        // Make sure SwiftUI registers the EnvironmentObject dependency for observation
        wrappedView.id(viewModel.isPresented)
    }
}

open class MacRouter: Router {
    let hostingController: NSHostingController<AnyView>
    let parentRouter: (Router, PresentationContext)?
    
    /// key: `ObjectIdentifier` of the `HostingController`
    fileprivate var routeHosts: [RouteViewIdentifier: RouteHost] = [:]
    fileprivate var stack = [RouteHost]()
    
    /// 🗑 Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    
    public init<Root>(
        root: Root,
        _ environmentObject: Root.EnvironmentObjectDependency,
        parent: (Router, PresentationContext)? = nil
    ) where Root: Route {
        self.hostingController =  NSHostingController(rootView: AnyView(EmptyView()))
        self.parentRouter = parent
        replaceRoot(with: root, environmentObject)
    }
    
    public init<Root>(
        root: Root
    ) where Root: Route {
        self.hostingController =  NSHostingController(rootView: AnyView(EmptyView()))
        self.parentRouter = nil
        replaceRoot(with: root)
    }
    
    // MARK: Root view replacement
    
    open func replaceRoot<Target: EnvironmentDependentRoute>(
        with target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency
    ) {
        navigate(to: target, environmentObject, using: DestinationPresenter())
    }
    
    open func replaceRoot<Target: Route>(
        with target: Target
    ) {
        self.replaceRoot(with: target, VoidObservableObject())
    }
    
    // MARK: Navigation
    
    fileprivate func topLevelRouteHost() -> RouteHost? {
        stack.last
    }
    
    /// - note: Not an implementation of the protocol requirement.
    @discardableResult
    open func navigate<Target, ThePresenter>(
        to target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter,
        source: RouteViewIdentifier?
    ) -> RouteViewIdentifier where Target : EnvironmentDependentRoute, ThePresenter : Presenter {
        func topLevelRouteHostOrNew() -> RouteHost {
            if let topHost = topLevelRouteHost() {
                return topHost
            } else {
                debugPrint("⚠️ Presenting route host for replacing presenter \(presenter) as root view, because an eligible view for presentation was not found.")
                
                let id = RouteViewIdentifier()
                let view = makeView(for: target, environmentObject: environmentObject, using: presenter, routeViewId: id)
                let routeHost = registerRouteHost(view: view, byRouteViewId: id)
                return routeHost
            }
        }
        
        let targetRouteViewId = RouteViewIdentifier()
        
        if !presenter.replacesParent { // Push 💨
            let view = makeView(for: target, environmentObject: environmentObject, using: presenter, routeViewId: targetRouteViewId)
            registerRouteHost(view: view, byRouteViewId: targetRouteViewId)
            hostingController.rootView = view
        } else {
            let host: RouteHost
            
            if let source = source {
                if let theHost = routeHosts[source] {
                    host = theHost
                } else {
                    debugPrint("⚠️ Trying to present on top of nonexisting source")
                    
                    host = topLevelRouteHostOrNew()
                }
            } else {
                host = topLevelRouteHostOrNew()
            }
            
            let state = target.prepareState(environmentObject: environmentObject)
            let presenterViewModel = PresenterViewModel()
            
            let presentationContext = PresentationContext(
                parent: host.root,
                destination: AnyView(adjustView(target.body(state: state), environmentObject: environmentObject, routeViewId: targetRouteViewId)),
                isPresented: Binding(
                    get: {
                        presenterViewModel.isPresented
                    },
                    set: { newValue in
                        presenterViewModel.isPresented = newValue
                    }
                )
            ) { [unowned self] rootRoute, presentationContext in
                self.makeChildRouterView(rootRoute: rootRoute, presentationContext: presentationContext, presenterViewModel: presenterViewModel)
            }
            
            presenterViewModel.$isPresented
                .first { $0 == false }
                .sink { [weak hostingController] _ in
                    hostingController?.rootView = AnyView(presenter.body(with: presentationContext)) }
                .store(in: &cancellables)
            
            let view = AnyView(presenter.body(with: presentationContext))
            registerRouteHost(view: view, byRouteViewId: targetRouteViewId)
            hostingController.rootView = view
        }
        
        return targetRouteViewId
    }
    
    public func dismissUpTo(routeMatchesId id: RouteViewIdentifier) {
        while !routeHosts.isEmpty, let lastRouteHost = stack.last {
            guard
                let route = routeHosts.first(where: { $0.value == lastRouteHost })
            else {
                if let (parentRouter, presentationContext) = parentRouter {
                    #warning("When dismissing `self` as a child of `parentRouter`, make sure the current presenter is removed from the hierarchy by replacing the hierarchy with the routeHost.rootView")
                    presentationContext.isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        parentRouter.dismissUpTo(routeMatchesId: id)
                    }
                    return
                }
                
                debugPrint("⚠️ Cannot dismiss route that's not in the hierarchy")
                return
            }
            
            if id == route.key {
                // Found the route we're looking for, but this is up to not including
                if let newRoot = stack.last?.root {
                    hostingController.rootView = newRoot
                }
                return
            }
            
            routeHosts[route.key] = nil
            stack.removeLast()
        }
    }
    
    public func dismissUpToIncluding(routeMatchingId id: RouteViewIdentifier) {
        while !routeHosts.isEmpty, let lastRouteHost = stack.last {
            guard
                let route = routeHosts.first(where: { $0.value == lastRouteHost })
            else {
                if let (parentRouter, presentationContext) = parentRouter {
                    #warning("When dismissing `self` as a child of `parentRouter`, make sure the current presenter is removed from the hierarchy by replacing the hierarchy with the routeHost.rootView")
                    presentationContext.isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        parentRouter.dismissUpTo(routeMatchesId: id)
                    }
                    return
                }
                
                debugPrint("⚠️ Cannot dismiss route that's not in the hierarchy")
                return
            }
            
            routeHosts[route.key] = nil
            stack.removeLast()
            
            if id == route.key {
                // Found the route we're looking for, and this is up to AND including
                if let newRoot = stack.last?.root {
                    hostingController.rootView = newRoot
                }
                return
            }
        }
    }
    
    // MARK: Customisation points
    
    /// Generate the view controller (usually a hosting controller) for the given destination.
    /// - Parameter destination: A destination to route to.
    /// - Returns: A view controller for showing `destination`.
    open func makeView<Target: EnvironmentDependentRoute, ThePresenter: Presenter>(for target: Target, environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter, routeViewId: RouteViewIdentifier) -> AnyView {
        let state = target.prepareState(environmentObject: environmentObject)
        let presenterViewModel = PresenterViewModel()
        
        let context = PresentationContext(
            parent: EmptyView(),
            destination: target.body(state: state),
            isPresented: isPresentedBinding(forRouteMatchingId: routeViewId, presenterViewModel: presenterViewModel)
        ) { [unowned self] rootRoute, presentationContext in
            self.makeChildRouterView(
                rootRoute: rootRoute,
                presentationContext: presentationContext,
                presenterViewModel: presenterViewModel
            )
        }
        
        return AnyView(adjustView(
            presenter.body(with: context),
            environmentObject: environmentObject,
            routeViewId: routeViewId
        ))
    }
    
    func adjustView<Input: View, Dependency: ObservableObject>(_ view: Input, environmentObject: Dependency, routeViewId: RouteViewIdentifier) -> some View {
        view
            .environment(\.router, self)
            .environmentObject(VoidObservableObject())
            .environmentObject(environmentObject)
            .environment(\.routeViewId, routeViewId)
            .id(routeViewId)
    }
    
    @discardableResult
    fileprivate func registerRouteHost(view: AnyView, byRouteViewId routeViewId: RouteViewIdentifier) -> RouteHost {
        let routeHost = RouteHost(root: view)
        routeHosts[routeViewId] = routeHost
        stack.append(routeHost)
        
        return routeHost
    }
    
    func makeChildRouterView<RootRoute: Route>(
        rootRoute: RootRoute,
        presentationContext: PresentationContext,
        presenterViewModel: PresenterViewModel
    ) -> AnyView {
        let router = MacRouter(
            root: rootRoute,
            VoidObservableObject(),
            parent: (self, presentationContext)
        )
        return AnyView(PresenterView(wrappedView: MacRouterView(router: router), viewModel: presenterViewModel))
    }
    
    public func isPresenting(routeMatchingId id: RouteViewIdentifier) -> Bool {
        guard let routeHost = routeHosts[id] else {
            return false
        }
        
        return stack.contains(routeHost)
    }
    
    private func isPresentedBinding(forRouteMatchingId id: RouteViewIdentifier, presenterViewModel: PresenterViewModel) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.isPresenting(routeMatchingId: id) ?? false
            },
            set: { [weak self] newValue in
                if !newValue {
                    self?.dismissUpToIncluding(routeMatchingId: id)
                }
            }
        )
    }
}
#endif
