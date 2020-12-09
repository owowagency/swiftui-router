import SwiftUI

@available(iOS 13, *)
public protocol Router {
    func navigate<Target: Route>(to target: Target, environment: EnvironmentValues)
    func replaceRoot<Target: Route>(with target: Target, environment: EnvironmentValues)
}

@available(iOS 13, *)
public extension Router {
    func replaceRoot<Target: Route>(with destination: Destination<Target>, environment: EnvironmentValues) {
        replaceRoot(with: destination.route, environment: environment)
    }
}
