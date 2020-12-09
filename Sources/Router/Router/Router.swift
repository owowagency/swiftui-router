import SwiftUI

@available(iOS 13, *)
public protocol Router {
    func navigate<Target: Route>(to target: Target, environment: EnvironmentValues, environmentObject: Target.EnvironmentObjectDependency)
    func replaceRoot<Target: Route>(with target: Target, environment: EnvironmentValues, environmentObject: Target.EnvironmentObjectDependency)
}
