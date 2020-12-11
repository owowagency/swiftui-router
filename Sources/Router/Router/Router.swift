import SwiftUI

@available(iOS 13, macOS 10.15, *)
public protocol Router {
    @discardableResult
    func navigate<Target, ThePresenter>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter, source: RouteViewIdentifier?) -> RouteViewIdentifier where Target: Route, ThePresenter: Presenter
}

@available(iOS 13, macOS 10.15, *)
public extension Router {
    @discardableResult
    func navigate<Target, ThePresenter>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter) -> RouteViewIdentifier where Target: Route, ThePresenter: Presenter {
        navigate(to: target, environmentObject, using: presenter, source: nil)
    }
}
