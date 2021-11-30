import SwiftUI

@available(iOS 13, macOS 10.15, *)
struct WeakRouter<R: Router & AnyObject>: Router {
    weak var _router: R?
    
    func navigate<Target, ThePresenter>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter, source: RouteViewIdentifier?) -> RouteViewIdentifier where Target : EnvironmentDependentRoute, ThePresenter : Presenter {
        _router?.navigate(to: target, environmentObject, using: presenter, source: source) ?? .init()
    }
    
    func replaceRoot<Target, ThePresenter>(with target: Target, _ environmentObject: Target.EnvironmentObjectDependency, using presenter: ThePresenter) -> RouteViewIdentifier where Target : EnvironmentDependentRoute, ThePresenter : Presenter {
        _router?.replaceRoot(with: target, environmentObject, using: presenter) ?? .init()
    }
    
    func dismissUpTo(routeMatchingId id: RouteViewIdentifier) {
        _router?.dismissUpTo(routeMatchingId: id)
    }
    
    func dismissUpToIncluding(routeMatchingId id: RouteViewIdentifier) {
        _router?.dismissUpToIncluding(routeMatchingId: id)
    }
    
    func isPresenting(routeMatchingId id: RouteViewIdentifier) -> Bool {
        _router?.isPresenting(routeMatchingId: id) ?? false
    }
}

@available(iOS 13, macOS 10.15, *)
fileprivate struct RouterKey: EnvironmentKey {
    typealias Value = Router?
    
    static var defaultValue: Router? = nil
}

@available(iOS 13, macOS 10.15, *)
public extension EnvironmentValues {
    var router: Router? {
        get {
            self[RouterKey.self]
        }
        set {
            self[RouterKey.self] = newValue
        }
    }
}
