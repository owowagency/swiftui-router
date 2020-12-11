#if canImport(UIKit)
import UIKit
import SwiftUI

@available(iOS 13, macOS 10.15, *)
final class RouteHost: Hashable {
    
    // MARK: State
    
    let root: AnyView
    weak var hostingController: UIHostingController<AnyView>?
    
    // MARK: Init
    
    init(root: AnyView, hostingController: UIHostingController<AnyView>) {
        self.root = root
        self.hostingController = hostingController
    }
    
    func reset() {
        hostingController?.rootView = root
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
extension Set where Element == RouteHost {
    mutating func garbageCollect() {
        self = self.filter { $0.hostingController != nil }
    }
}

public struct RouteViewIdentifier: Hashable {
    private static var id = 0
    let id: Int
    
    init() {
        self.id = Self.id
        Self.id += 1
    }
}

/// A `Router` implementation that pushes routed views onto a `UINavigationController`.
@available(iOS 13, *)
open class UINavigationControllerRouter: Router {
    public let navigationController: UINavigationController
    
    /// key: `ObjectIdentifier` of the `HostingController`
    private var routeHosts: [RouteViewIdentifier: RouteHost] = [:]
    
    /// 🌷
    /// - Parameter navigationController: The navigation controller to use for routing.
    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root, _ environmentObject: Root.EnvironmentObjectDependency) where Root: Route {
        self.navigationController = navigationController
        navigate(to: root, environmentObject, using: DestinationPresenter())
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root) where Root: Route, Root.EnvironmentObjectDependency == VoidObservableObject {
        self.navigationController = navigationController
        navigate(to: root, .init(), using: DestinationPresenter())
    }
    
    // MARK: Root view replacement
    
    open func replaceRoot<Target: Route, ThePresenter: Presenter>(with target: Target, _ environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter) {
        unimplemented()
//        let viewController = makeViewController(for: target, environmentObject: environmentObject, using: presenter)
//        navigationController.viewControllers = [viewController]
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
    open func navigate<Target, ThePresenter>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter, source: RouteViewIdentifier?) -> RouteViewIdentifier where Target : Route, ThePresenter : Presenter {
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
        
        if !presenter.replacesParent { // Push 💨
            let viewController = makeViewController(for: target, environmentObject: environmentObject, using: presenter, routeViewId: targetRouteViewId)
            registerHostingController(hostingController: viewController, byRouteViewId: targetRouteViewId)
            navigationController.pushViewController(viewController, animated: true)
        } else {
            let host: RouteHost
            let hostingController: UIHostingController<AnyView>
            
            if let source = source {
                if let theHost = routeHosts[source], let viewController = theHost.hostingController {
                    host = theHost
                    hostingController = viewController
                } else {
                    debugPrint("⚠️ Trying to present on top of nonexisting source")
                    
                    (host, hostingController) = topLevelRouteHostOrNew()
                }
            } else {
                (host, hostingController) = topLevelRouteHostOrNew()
            }
            
            let state = target.prepareState(environmentObject: environmentObject)
            
            let presented = presenter.body(
                from: host.root,
                to: AnyView(adjustView(target.body(state: state), environmentObject: environmentObject, routeViewId: targetRouteViewId))
            )
            
            hostingController.rootView = AnyView(presented)
        }
        
        return targetRouteViewId
    }
    
    // MARK: Customisation points
    
    /// Generate the view controller (usually a hosting controller) for the given destination.
    /// - Parameter destination: A destination to route to.
    /// - Returns: A view controller for showing `destination`.
    open func makeViewController<Target: Route, ThePresenter: Presenter>(for target: Target, environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter, routeViewId: RouteViewIdentifier) -> UIHostingController<AnyView> {
        let state = target.prepareState(environmentObject: environmentObject)
        
        return makeHostingController(
            // TODO: Pass source view
            rootView: adjustView(
                presenter.body(
                    from: AnyView(EmptyView()),
                    to: AnyView(target.body(state: state))
                ),
                environmentObject: environmentObject,
                routeViewId: routeViewId
            )
        )
    }
    
    func adjustView<Input: View, Dependency: ObservableObject>(_ view: Input, environmentObject: Dependency, routeViewId: RouteViewIdentifier) -> some View {
        view
            .environment(\.router, self)
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
    func registerHostingController(hostingController: UIHostingController<AnyView>, byRouteViewId routeViewId: RouteViewIdentifier) -> RouteHost {
        assert(!routeHosts.values.contains { $0.hostingController === hostingController })
        
        let routeHost = RouteHost(root: hostingController.rootView, hostingController: hostingController)
        routeHosts[routeViewId] = routeHost
        
        return routeHost
    }
}
#endif
