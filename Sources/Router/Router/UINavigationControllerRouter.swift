#if canImport(UIKit)
import UIKit
import SwiftUI
import Combine

@available(iOS 13, macOS 10.15, *)
fileprivate final class RouteHost: Hashable {
    
    // MARK: State
    
    private let root: AnyView
    weak var hostingController: UIHostingController<AnyView>?
    
    func root<Sibling: View>(sibling: Sibling) -> some View {
        self.root
            .overlay(AnyView(sibling))
    }
    
    // MARK: Init
    
    init(hostingController: UIHostingController<AnyView>) {
        self.root = hostingController.rootView
        self.hostingController = hostingController
        
        // Doing this ensures that the root view is of a stable type and structure, preventing
        // SwiftUI from resetting everything when presenting a sibling view.
        hostingController.rootView = AnyView(self.root(sibling: EmptyView()))
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
extension Dictionary where Value == RouteHost {
    mutating func garbageCollect() {
        self = self.filter { $0.value.hostingController != nil }
    }
}

/// A `Router` implementation that pushes routed views onto a `UINavigationController`.
@available(iOS 13, *)
open class UINavigationControllerRouter: Router {
    public let navigationController: UINavigationController
    let parentRouter: (Router, PresentationContext)?
    
    private var routeHosts: [RouteViewIdentifier: RouteHost] = [:]
    
    /// A reference to the presenter view models of presented child routes. Used for dismissal support.
    private var presenterViewModels: [RouteViewIdentifier: PresenterViewModel] = [:]
    
    /// 🗑 Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    
    /// 🌷
    /// - Parameter navigationController: The navigation controller to use for routing.
    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        self.parentRouter = nil
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root, _ environmentObject: Root.EnvironmentObjectDependency, parent: (Router, PresentationContext)? = nil) where Root: EnvironmentDependentRoute {
        self.navigationController = navigationController
        self.parentRouter = parent
        navigate(to: root, environmentObject, using: DestinationPresenter())
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root) where Root: Route {
        self.navigationController = navigationController
        self.parentRouter = nil
        navigate(to: root, .init(), using: DestinationPresenter())
    }
    
    // MARK: Root view replacement
    
    open func replaceRoot<Target, ThePresenter>(
        with target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter
    ) -> RouteViewIdentifier where Target : EnvironmentDependentRoute, ThePresenter : Presenter {
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true, completion: nil)
        }
        
        navigationController.viewControllers = []
        routeHosts.removeAll()
        return navigate(to: target, environmentObject, using: presenter)
    }
    
    // MARK: Navigation
    
    private func topLevelRouteHost() -> RouteHost? {
        for controller in navigationController.viewControllers.reversed() {
            if let routeHost = routeHosts.values.first(where: { $0.hostingController === controller }) {
                return routeHost
            }
        }
        
        return nil
    }
    
    /// - note: Not an implementation of the protocol requirement.
    @discardableResult
    open func navigate<Target, ThePresenter>(
        to target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter, source: RouteViewIdentifier?
    ) -> RouteViewIdentifier where Target : EnvironmentDependentRoute, ThePresenter : Presenter {
        routeHosts.garbageCollect()
        
        func topLevelRouteHostOrNew() -> (RouteHost, UIHostingController<AnyView>) {
            if let topHost = topLevelRouteHost(), let viewController = topHost.hostingController {
                return (topHost, viewController)
            } else {
                debugPrint("⚠️ Presenting route host for replacing presenter \(presenter) as root view, because an eligible view for presentation was not found.")
                
                let id = RouteViewIdentifier()
                let viewController = makeViewController(for: target, environmentObject: environmentObject, using: presenter, routeViewId: id)
                let routeHost = registerHostingController(hostingController: viewController, byRouteViewId: id)
                return (routeHost, viewController)
            }
        }
        
        let targetRouteViewId = RouteViewIdentifier()
        
        switch presenter.presentationMode {
        case .normal: // Push 💨
            let viewController = makeViewController(for: target, environmentObject: environmentObject, using: presenter, routeViewId: targetRouteViewId)
            registerHostingController(hostingController: viewController, byRouteViewId: targetRouteViewId)
            
            if navigationController.viewControllers.isEmpty {
                // For some reason, this is needed to work reliably on iOS 13.
                // On iOS 14, just pusing onto the empty navigation controller works fine.
                navigationController.viewControllers = [viewController]
            } else {
                navigationController.pushViewController(viewController, animated: true)
            }
        case .replaceParent, .sibling:
            let host: RouteHost
            let hostingController: UIHostingController<AnyView>
            
            if let source = source, source != .none {
                if let theHost = routeHosts[source], let viewController = theHost.hostingController {
                    host = theHost
                    hostingController = viewController
                } else {
                    debugPrint("⚠️ Trying to present on top of nonexisting source")
                    
                    (host, hostingController) = topLevelRouteHostOrNew()
                }
            } else {
                (host, hostingController) = topLevelRouteHostOrNew()
                
                if navigationController.viewControllers.isEmpty {
                    navigationController.viewControllers = [
                        hostingController
                    ]
                    return targetRouteViewId
                }
            }
            
            let state = target.prepareState(environmentObject: environmentObject)
            let presenterViewModel = PresenterViewModel()
            self.presenterViewModels[targetRouteViewId] = presenterViewModel
            
            let isPresentedBinding: Binding<Bool> = Binding(
                get: {
                    presenterViewModel.isPresented
                },
                set: { [weak self] newValue in
                    presenterViewModel.isPresented = newValue
                    
                    if newValue == false {
                        self?.presenterViewModels[targetRouteViewId] = nil
                        
                        // Remove the presenter from the host.
                        DispatchQueue.main.async {
                            // Wait until the next iteration of the run loop, for example for sheet modifiers to dismiss themselves before removing them.
                            hostingController.rootView = AnyView(host.root(sibling: EmptyView()))
                        }
                    } else {
                        self?.presenterViewModels[targetRouteViewId] = presenterViewModel
                    }
                }
            )
            
            let makeRouter: PresentationContext.RouterViewFactory = { [unowned self] presentationContext in
                self.makeChildRouterView(
                    rootRoute: SimpleRoute(
                        dependency: Target.EnvironmentObjectDependency.self,
                        prepareState: { _ in state },
                        body: target.body
                    ),
                    environmentObject: environmentObject,
                    presentationContext: presentationContext,
                    presenterViewModel: presenterViewModel
                )
            }
            
            let presentationContext: PresentationContext
            
            switch presenter.presentationMode {
            case .replaceParent:
                presentationContext = PresentationContext(
                    parent: host.root(sibling: EmptyView()),
                    destination: AnyView(adjustView(target.body(state: state), environmentObject: environmentObject, routeViewId: targetRouteViewId)),
                    isPresented: isPresentedBinding,
                    makeRouter: makeRouter
                )
                
                hostingController.rootView = AnyView(presenter.body(with: presentationContext))
            case .sibling: // Overlay parent with child
                presentationContext = PresentationContext(
                    parent: EmptyView(),
                    destination: adjustView(target.body(state: state), environmentObject: environmentObject, routeViewId: targetRouteViewId),
                    isPresented: isPresentedBinding,
                    makeRouter: makeRouter
                )
                
                hostingController.rootView = AnyView(host.root(sibling: presenter.body(with: presentationContext)))
            case .normal:
                fatalError("Internal inconsistency")
            }
            
            presenterViewModel.$isPresented
                .first { $0 == false }
                .sink { [weak hostingController] _ in
                    hostingController?.rootView = AnyView(host.root(sibling: EmptyView())) }
                .store(in: &cancellables)
        }
        
        return targetRouteViewId
    }
    
    /// Dismiss all up to, but not including, the root route
    public func dismissToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
    
    /// Dismisses up to, but not including, the given `id`, so the route with that identifier becomes the topmost route.
    /// - Parameter id: The `id` of the route to dismiss up to.
    public func dismissUpTo(routeMatchingId id: RouteViewIdentifier) {
        guard let hostingController = routeHosts[id]?.hostingController else {
            if let (parentRouter, presentationContext) = parentRouter {
                presentationContext.isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    parentRouter.dismissUpTo(routeMatchingId: id)
                }
                return
            }
            
            debugPrint("⚠️ Cannot dismiss route that's not in the hierarchy")
            return
        }
        navigationController.popToViewController(hostingController, animated: true)
        
        if hostingController.presentedViewController != nil {
            hostingController.dismiss(animated: true, completion: nil)
        }
    }
    
    public func dismissUpToIncluding(routeMatchingId id: RouteViewIdentifier) {
        guard let hostingController = routeHosts[id]?.hostingController else {
            if let presenterViewModel = presenterViewModels[id] {
                presenterViewModel.isPresented = false
                return
            }
            
            if let (parentRouter, presentationContext) = parentRouter {
                presentationContext.isPresented = false
                DispatchQueue.main.async {
                    parentRouter.dismissUpTo(routeMatchingId: id)
                }
                return
            }
            
            debugPrint("⚠️ Cannot dismiss route that's not in the hierarchy")
            return
        }
        
        if let viewControllerIndex = navigationController.viewControllers.firstIndex(of: hostingController) {
            if viewControllerIndex == 0 {
                if let parentRouter = parentRouter {
                    parentRouter.1.isPresented = false
                } else {
                    debugPrint("⚠️ Dismissal of root route is not possible")
                    navigationController.popToRootViewController(animated: true)
                }
                return
            }
            
            let viewControllerBefore = navigationController.viewControllers[viewControllerIndex - 1]
            
            navigationController.popToViewController(viewControllerBefore, animated: true)
        } else {
            debugPrint("Dismissal of route whose view controller is not presented by the navigation controller")
        }
    }
    
    // MARK: Customisation points
    
    /// Generate the view controller (usually a hosting controller) for the given destination.
    /// - Parameter destination: A destination to route to.
    /// - Returns: A view controller for showing `destination`.
    open func makeViewController<Target: EnvironmentDependentRoute, ThePresenter: Presenter>(
        for target: Target,
        environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter,
        routeViewId: RouteViewIdentifier
    ) -> UIHostingController<AnyView> {
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
        
        return makeHostingController(
            // TODO: Pass source view
            rootView: adjustView(
                presenter.body(with: context),
                environmentObject: environmentObject,
                routeViewId: routeViewId
            )
        )
    }
    
    func adjustView<Input: View, Dependency: ObservableObject>(_ view: Input, environmentObject: Dependency, routeViewId: RouteViewIdentifier) -> some View {
        view
            .environment(\.router, WeakRouter(_router: self))
            .environmentObject(VoidObservableObject())
            .environmentObject(environmentObject)
            .environment(\.routeViewId, routeViewId)
    }
    
    /// Takes a `View` and creates a hosting controller for it.
    ///
    /// If you need to add any additional customisations (for example, modifiers) to all views that you navigate to, this is the method you probably want to override.
    open func makeHostingController<Root: View>(rootView: Root) -> UIHostingController<AnyView> {
        return UIHostingController(rootView: AnyView(rootView))
    }
    
    @discardableResult
    fileprivate func registerHostingController(hostingController: UIHostingController<AnyView>, byRouteViewId routeViewId: RouteViewIdentifier) -> RouteHost {
        assert(!routeHosts.values.contains { $0.hostingController === hostingController })
        
        let routeHost = RouteHost(hostingController: hostingController)
        routeHosts[routeViewId] = routeHost
        
        return routeHost
    }
    
    func makeChildRouterView<RootRoute: EnvironmentDependentRoute>(
        rootRoute: RootRoute,
        environmentObject: RootRoute.EnvironmentObjectDependency,
        presentationContext: PresentationContext,
        presenterViewModel: PresenterViewModel
    ) -> AnyView {
        let router = makeChildRouter(rootRoute: rootRoute, environmentObject: environmentObject, presentationContext: presentationContext, presenterViewModel: presenterViewModel)
        return AnyView(PresenterView(wrappedView: UINavigationControllerRouterView(router: router), viewModel: presenterViewModel))
    }
    
    open func makeChildRouter<RootRoute: EnvironmentDependentRoute>(
        rootRoute: RootRoute,
        environmentObject: RootRoute.EnvironmentObjectDependency,
        presentationContext: PresentationContext,
        presenterViewModel: PresenterViewModel
    ) -> UINavigationControllerRouter {
        return UINavigationControllerRouter(
            root: rootRoute,
            environmentObject,
            parent: (self, presentationContext)
        )
    }
    
    public func isPresenting(routeMatchingId id: RouteViewIdentifier) -> Bool {
        guard let viewController = routeHosts[id]?.hostingController else {
            return false
        }
        
        return navigationController.viewControllers.contains(viewController)
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
#endif
