import SwiftUI

#if canImport(UIKit)
@available(iOS 13, *)
public struct StackRouterView: View {
    @State var router: UINavigationControllerRouter
    
    public init<RootRoute: Route>(root: RootRoute) {
        self._router = State(wrappedValue: UINavigationControllerRouter(root: root))
    }
    
    public init<RootRoute: EnvironmentDependentRoute>(root: RootRoute, dependency: RootRoute.EnvironmentObjectDependency) {
        self._router = State(wrappedValue: UINavigationControllerRouter(root: root, dependency))
    }
    
    public init(router: UINavigationControllerRouter) {
        self._router = State(wrappedValue: router)
    }
    
    public var body: some View {
        UINavigationControllerRouterView(router: router)
    }
}
#endif
