import SwiftUI
import Combine

/// A type-erased environment dependent route.
@available(iOS 13, macOS 10.15, *)
public struct AnyEnvironmentDependentRoute<EnvironmentObjectDependency: ObservableObject>: EnvironmentDependentRoute {
    private var _prepareState: (EnvironmentObjectDependency) -> Any
    private var _body: (State) -> AnyView
    
    public typealias State = Any
    
    /// Create an instance that type-erases `route`.
    public init<R>(_ route: R) where R: EnvironmentDependentRoute, R.EnvironmentObjectDependency == EnvironmentObjectDependency {
        self._prepareState = { route.prepareState(environmentObject: $0) }
        self._body = {
            guard let state = $0 as? R.State else {
                fatalError("internal inconsistency: AnyRoute body called with mismatching state argument")
            }
            
            return AnyView(route.body(state: state))
        }
    }
    
    /// Create an instance that type-erases `route`.
    ///
    /// This initializer variant supports type-erasing a route that isn't dependent on the environment to one that is.
    public init<R>(_ route: R) where R: Route {
        self._prepareState = { _ in route.prepareState(environmentObject: VoidObservableObject()) }
        self._body = Self.makeBody(route: route)
    }
    
    private static func makeBody<R>(route: R) -> ((State) -> AnyView) where R: Route {
        return {
            guard let state = $0 as? R.State else {
                fatalError("internal inconsistency: AnyRoute body called with mismatching state argument")
            }
            
            return AnyView(route.body(state: state))
        }
    }
    
    public func prepareState(environmentObject: EnvironmentObjectDependency) -> State {
        _prepareState(environmentObject)
    }
    
    public func body(state: State) -> some View {
        _body(state)
    }
}
