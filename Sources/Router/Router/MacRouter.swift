#if canImport(AppKit)
import Combine
import SwiftUI

@available(macOS 10.15, *)
fileprivate final class RouteHost: Hashable {
    
    // MARK: State
    
    let rootView: AnyView
    
    func root<Sibling: View>(sibling: Sibling) -> some View {
        self.rootView
            .overlay(AnyView(sibling))
    }
    
    // MARK: Init
    
    init(rootView: AnyView) {
        self.rootView = rootView
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
public class PresenterViewModel: ObservableObject {
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
        rootView: Root,
        _ environmentObject: Root.EnvironmentObjectDependency,
        parent: (Router, PresentationContext)? = nil
    ) where Root: EnvironmentDependentRoute {
        self.hostingController =  NSHostingController(rootView: AnyView(EmptyView()))
        self.parentRouter = parent
        replaceRoot(with: rootView, environmentObject)
    }
    
    public init<Root>(
        rootView: Root
    ) where Root: Route {
        self.hostingController =  NSHostingController(rootView: AnyView(EmptyView()))
        self.parentRouter = nil
        replaceRoot(with: rootView)
    }
    
    // MARK: Root view replacement
    
    open func replaceRoot<Target, ThePresenter>(
        with target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter
    ) -> RouteViewIdentifier where Target : EnvironmentDependentRoute, ThePresenter : Presenter {
        self.stack.removeAll(keepingCapacity: true)
        self.routeHosts.removeAll(keepingCapacity: true)
        self.hostingController.rootView = AnyView(EmptyView())
        
        return navigate(
            to: target,
            environmentObject,
            using: presenter,
            source: nil
        )
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
        
        switch presenter.presentationMode {
        case .normal: // Push 💨
            let view = makeView(for: target, environmentObject: environmentObject, using: presenter, routeViewId: targetRouteViewId)
            registerRouteHost(view: view, byRouteViewId: targetRouteViewId)
            hostingController.rootView = view
        case .replaceParent, .sibling:
            let host: RouteHost
            
            if let source = source, source != .none {
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
            let presentationContext: PresentationContext
            
            let isPresentedBinding = Binding<Bool>(
                get: {
                    presenterViewModel.isPresented
                },
                set: { newValue in
                    presenterViewModel.isPresented = newValue
                }
            )
            
            let makeRouter: PresentationContext.RouterViewFactory = { [unowned self] presentationContext in
                self.makeChildRouterView(
                    rootRoute: target,
                    environmentObject: environmentObject,
                    presentationContext: presentationContext,
                    presenterViewModel: presenterViewModel
                )
            }
            
            switch presenter.presentationMode {
            case .replaceParent:
                presentationContext = PresentationContext(
                    parent: host.root(sibling: EmptyView()),
                    destination: AnyView(adjustView(target.body(state: state), environmentObject: environmentObject, routeViewId: targetRouteViewId)),
                    isPresented: isPresentedBinding,
                    makeRouter: makeRouter
                )
                
                let view = AnyView(presenter.body(with: presentationContext))
                registerRouteHost(view: view, byRouteViewId: targetRouteViewId)
                hostingController.rootView = view
            case .sibling:
                presentationContext = PresentationContext(
                    parent: EmptyView(),
                    destination: adjustView(target.body(state: state), environmentObject: environmentObject, routeViewId: targetRouteViewId),
                    isPresented: isPresentedBinding,
                    makeRouter: makeRouter
                )
                
                let view = AnyView(presenter.body(with: presentationContext))
                registerRouteHost(view: view, byRouteViewId: targetRouteViewId)
                
                hostingController.rootView = AnyView(host.root(sibling: presenter.body(with: presentationContext)))
            case .normal:
                fatalError("Internal inconsistency")
            }
            
            presenterViewModel.$isPresented
                .first { $0 == false }
                .sink { [weak hostingController] _ in
                    hostingController?.rootView = AnyView(presenter.body(with: presentationContext)) }
                .store(in: &cancellables)
        }
        
        return targetRouteViewId
    }
    
    public func dismissUpTo(routeMatchesId id: RouteViewIdentifier) {
        while !routeHosts.isEmpty, let lastRouteHost = stack.last {
            guard
                let route = routeHosts.first(where: { $0.value == lastRouteHost })
            else {
                if let (parentRouter, presentationContext) = parentRouter {
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
                if let newRoot = stack.last?.rootView {
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
                if let newRoot = stack.last?.rootView {
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
        ) { [unowned self] presentationContext in
            self.makeChildRouterView(
                rootRoute: target,
                environmentObject: environmentObject,
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
        let routeHost = RouteHost(rootView: view)
        routeHosts[routeViewId] = routeHost
        stack.append(routeHost)
        
        return routeHost
    }
    
    func makeChildRouterView<RootRoute: EnvironmentDependentRoute>(
        rootRoute: RootRoute,
        environmentObject: RootRoute.EnvironmentObjectDependency,
        presentationContext: PresentationContext,
        presenterViewModel: PresenterViewModel
    ) -> AnyView {
        let router = MacRouter(
            rootView: rootRoute,
            environmentObject,
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
