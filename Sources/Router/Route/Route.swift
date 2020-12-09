import SwiftUI

/// A route represents a navigatable destination. It contains everything a `Router` needs to present a destination on the screen.
@available(iOS 13, *)
public protocol Route {
    /// The `State` type of the route. The body (view) is defined as a product of the state.
    associatedtype State
    
    /// The body type of the Route – a SwiftUI view.
    associatedtype Body: View
    
    /// A route may depend on an EnvironmentObject in the environment. If a route doesn't depend on an environment, it can implement the `IndependentRoute` protocol instead of the `Route` protocol.
    associatedtype EnvironmentObjectDependency: ObservableObject
    
    /// Runs once when navigating to a route.
    func prepareState(environmentObject: EnvironmentObjectDependency) -> State
    
    /// The body of the Route, defined as a product of the `State`.
    func body(state: State) -> Body
}

@available(iOS 13, *)
public extension Route where State == Void {
    func prepareState(environmentObject: EnvironmentObjectDependency) -> State {
        ()
    }
}

