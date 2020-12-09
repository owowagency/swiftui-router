import SwiftUI

/// A route that isn't dependent on the environment for initialising it's state.
@available(iOS 13, macOS 10.15, *)
public protocol IndependentRoute: Route where Self.EnvironmentObjectDependency == VoidObservableObject {
    func prepareState() -> State
}

@available(iOS 13, macOS 10.15, *)
extension IndependentRoute {
    public func prepareState(environmentObject: EnvironmentObjectDependency) -> State {
        prepareState()
    }
}
