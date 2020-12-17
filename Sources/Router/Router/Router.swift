import SwiftUI

/// A router is responsible for presenting routes.
///
/// As part of this responsibility, it also has the following responsibilities:
/// - For all presented views, the router generates a `RouteViewIdentifier`
/// - The router prepares the environment for the presented views
///
/// As part of the environment preparation, the router should provide the following data to all presented routes:
/// - The router itself
/// - The `VoidObservableObject` instance
/// - The environment object dependency of the presented route
/// - The `RouteViewIdentifier` of the presented route
@available(iOS 13, macOS 10.15, *)
public protocol Router {
    
    // MARK: - Navigation
    
    /// Programatically navigate to the specified route.
    ///
    /// - Note: The preferred way to initiate navigation is by using `RouterLink` instead of this method.
    ///
    /// - Parameters:
    ///   - target: The route to navigate to.
    ///   - environmentObject: If the state preparation of the route depends on an environment object, the environment object.
    ///   - presenter: The presenter to use when navigating.
    ///   - source: The identifier of the view that initiated the navigation.
    @discardableResult
    func navigate<Target, ThePresenter>(
        to target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter,
        source: RouteViewIdentifier?
    ) -> RouteViewIdentifier where Target: EnvironmentDependentRoute, ThePresenter: Presenter
    
    /// Replaces the root view of the router with the given `target` route, replacing all current views.
    @discardableResult
    func replaceRoot<Target, ThePresenter>(
        with target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter
    ) -> RouteViewIdentifier where Target: EnvironmentDependentRoute, ThePresenter: Presenter
    
    // MARK: - Dismissal
    
    /// Dismiss up to, but not including, the route matching `id`.
    ///
    /// The actual dismissal behavior can differ between router implementations.
    func dismissUpTo(routeMatchesId id: RouteViewIdentifier)
    
    /// Dismiss all routes up to, and including, the route matching `id`.
    ///
    /// The actual dismissal behavior can differ between router implemetations.
    func dismissUpToIncluding(routeMatchingId id: RouteViewIdentifier)
    
    // MARK: - Querying the router
    
    /// Returns `true` if the router is currently presenting a route matching `id`.
    func isPresenting(routeMatchingId id: RouteViewIdentifier) -> Bool
    
}

@available(iOS 13, macOS 10.15, *)
public extension Router {
    
    // MARK: - Convenience navigation methods
    
    /// A variation on `navigate(to:_:using:source:)` without a source.
    @discardableResult
    func navigate<Target, ThePresenter>(
        to target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        using presenter: ThePresenter
    ) -> RouteViewIdentifier where Target: EnvironmentDependentRoute, ThePresenter: Presenter {
        navigate(to: target, environmentObject, using: presenter, source: nil)
    }
    
    /// A variation on `navigate(to:_:using:source:)` that uses `DestinationPresenter`.
    @discardableResult
    func navigate<Target>(
        to target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency,
        source: RouteViewIdentifier? = nil
    ) -> RouteViewIdentifier where Target: EnvironmentDependentRoute {
        navigate(to: target, environmentObject, using: DestinationPresenter(), source: source)
    }
    
    /// A variation on `navigate(to:_:using:source:)` without an EnvironmentObject dependency.
    @discardableResult
    func navigate<Target, ThePresenter>(
        to target: Target,
        using presenter: ThePresenter,
        source: RouteViewIdentifier? = nil
    ) -> RouteViewIdentifier where Target: Route, ThePresenter: Presenter {
        navigate(to: target, VoidObservableObject(), using: presenter, source: source)
    }
    
    /// A variation on `navigate(to:_:using:source:)` without an EnvironmentObject dependency that uses `DestinationPresenter`.
    @discardableResult
    func navigate<Target>(
        to target: Target,
        source: RouteViewIdentifier? = nil
    ) -> RouteViewIdentifier where Target: Route {
        navigate(to: target, VoidObservableObject(), source: source)
    }
    
    // MARK: - Convenience root replacement functions
    
    /// A variation of `replaceRoot(with:_:using:)` that uses `DestinationPresenter`.
    @discardableResult
    func replaceRoot<Target>(
        with target: Target,
        _ environmentObject: Target.EnvironmentObjectDependency
    ) -> RouteViewIdentifier where Target: EnvironmentDependentRoute {
        replaceRoot(with: target, environmentObject, using: DestinationPresenter())
    }
    
    /// A variation of `replaceRoot(with:_:using:)` without an EnvironmentObject dependency.
    @discardableResult
    func replaceRoot<Target, ThePresenter>(
        with target: Target,
        using presenter: ThePresenter
    ) -> RouteViewIdentifier where Target: Route, ThePresenter: Presenter {
        replaceRoot(with: target, VoidObservableObject(), using: presenter)
    }
    
    /// A variation of `replaceRoot(witH:_:using:)` without an EnvironmentObject dependency that uses `DestinationPresenter`.
    @discardableResult
    func replaceRoot<Target>(
        with target: Target
    ) -> RouteViewIdentifier where Target: Route {
        replaceRoot(with: target, VoidObservableObject(), using: DestinationPresenter())
    }
    
}
