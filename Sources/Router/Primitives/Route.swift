import SwiftUI

@available(iOS 13, *)
public protocol Route {
    associatedtype State
    associatedtype Body: View
    
    /// Runs once when navigating to a route.
    func prepareState(environment: EnvironmentValues) -> State
    func body(state: State) -> Body
}

@available(iOS 13, *)
public extension Route where State == Void {
    func prepareState() -> State {
        ()
    }
}
