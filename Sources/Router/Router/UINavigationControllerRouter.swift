#if canImport(UIKit)
import UIKit
import SwiftUI

/// A `Router` implementation that pushes routed views onto a `UINavigationController`.
@available(iOS 13, *)
open class UINavigationControllerRouter: Router {
    public let navigationController: UINavigationController
    let dependenciesBag = ObjectDependenciesBag()
    
    /// 🌷
    /// - Parameter navigationController: The navigation controller to use for routing.
    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root, _ environmentObject: Root.EnvironmentObjectDependency) where Root: Route {
        self.navigationController = navigationController
        dependenciesBag.addObjectDependency(environmentObject)
        replaceRoot(with: ParentPresentor.self, parent: root, child: VoidRoute())
    }
    
    public init<Root>(navigationController: UINavigationController = UINavigationController(), root: Root) where Root: Route, Root.EnvironmentObjectDependency == VoidObservableObject {
        self.navigationController = navigationController
        replaceRoot(with: ParentPresentor.self, parent: root, child: VoidRoute())
    }
    
    // MARK: Root view replacement
    
    public func navigate<Target>(with presentor: Target.Type, parent: Target.Parent, child: Target.Child) where Target : Presentor {
        let viewController = makeViewController(
            presentor: presentor,
            parent: parent,
            child: child
        )
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    public func replaceRoot<Target>(with presentor: Target.Type, parent: Target.Parent, child: Target.Child) where Target : Presentor {
        let viewController = makeViewController(
            presentor: presentor,
            parent: parent,
            child: child
        )
        
        navigationController.viewControllers = [viewController]
    }
    
    // MARK: Customisation points
    
    /// Generate the view controller (usually a hosting controller) for the given destination.
    /// - Parameter destination: A destination to route to.
    /// - Returns: A view controller for showing `destination`.
    open func makeViewController<Target: Presentor>(presentor: Target.Type, parent: Target.Parent, child: Target.Child) -> UIViewController {
        let view = presentor.present(
            parent: parent,
            child: child,
            dependenciesBag: dependenciesBag
        )
        
        return makeHostingController(rootView: view)
    }
    
    /// Takes a `View` and creates a hosting controller for it.
    ///
    /// If you need to add any additional customisations (for example, modifiers) to all views that you navigate to, this is the method you probably want to override.
    open func makeHostingController<Root: View>(rootView: Root) -> UIViewController {
        return UIHostingController(rootView: rootView)
    }
}
#endif
