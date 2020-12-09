import UIKit
import SwiftUI

/// A `Router` implementation that pushes routed views onto a `UINavigationController`.
@available(iOS 13, *)
open class UINavigationControllerRouter: Router {
    public let navigationController: UINavigationController
    
    /// 🌷
    /// - Parameter navigationController: The navigation controller to use for routing.
    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root, _ environmentObject: Root.EnvironmentObjectDependency) where Root: Route {
        self.navigationController = navigationController
        replaceRoot(with: root, environmentObject)
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root) where Root: Route, Root.EnvironmentObjectDependency == VoidObservableObject {
        self.navigationController = navigationController
        replaceRoot(with: root)
    }
    
    // MARK: Root view replacement
    
    open func replaceRoot<Target: Route>(with target: Target, _ environmentObject: Target.EnvironmentObjectDependency) {
        print("🚦 Replace root with \(target)")
        
        let viewController = makeViewController(for: target, environmentObject: environmentObject)
        navigationController.viewControllers = [viewController]
    }
    
    // MARK: Navigation
    
    /// - note: Not an implementation of the protocol requirement.
    open func navigate<Target: Route>(to target: Target, _ environmentObject: Target.EnvironmentObjectDependency) {
        print("🚦 Navigate to \(target)")
        
        let viewController = makeViewController(for: target, environmentObject: environmentObject)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    // MARK: Customisation points
    
    /// Generate the view controller (usually a hosting controller) for the given destination.
    /// - Parameter destination: A destination to route to.
    /// - Returns: A view controller for showing `destination`.
    open func makeViewController<Target: Route>(for target: Target, environmentObject: Target.EnvironmentObjectDependency) -> UIViewController {
        let state = target.prepareState(environmentObject: environmentObject)
        
        return makeHostingController(
            rootView: target.body(state: state)
                .environment(\.router, self)
                .environmentObject(VoidObservableObject())
        )
    }
    
    /// Takes a `View` and creates a hosting controller for it.
    ///
    /// If you need to add any additional customisations (for example, modifiers) to all views that you navigate to, this is the method you probably want to override.
    open func makeHostingController<Root: View>(rootView: Root) -> UIViewController {
        return UIHostingController(rootView: rootView)
    }
}
