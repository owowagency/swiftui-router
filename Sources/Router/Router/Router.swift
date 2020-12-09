import SwiftUI

@available(iOS 13, *)
public protocol Router {
    func navigate<Target>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency) where Target: Route
    func replaceRoot<Target>(with target: Target, _ environmentObject: Target.EnvironmentObjectDependency) where Target: Route
}

@available(iOS 13, *)
public extension Router {
    func navigate<Target>(to target: Target) where Target: Route, Target.EnvironmentObjectDependency == VoidEnvironmentObject {
        navigate(to: target, VoidEnvironmentObject())
    }
    
    func replaceRoot<Target>(with target: Target) where Target: Route, Target.EnvironmentObjectDependency == VoidEnvironmentObject {
        replaceRoot(with: target, VoidEnvironmentObject())
    }
}
