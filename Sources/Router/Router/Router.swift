import SwiftUI

@available(iOS 13, *)
public protocol Router {
    func navigate<Target>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency) where Target: Route
    func replaceRoot<Target>(with target: Target, _ environmentObject: Target.EnvironmentObjectDependency) where Target: Route
}

@available(iOS 13, *)
public extension Router {
    func navigate<Target>(to target: Target) where Target: Route, Target.EnvironmentObjectDependency == VoidObservableObject {
        navigate(to: target, VoidObservableObject())
    }
    
    func replaceRoot<Target>(with target: Target) where Target: Route, Target.EnvironmentObjectDependency == VoidObservableObject {
        replaceRoot(with: target, VoidObservableObject())
    }
}
