import SwiftUI

@available(iOS 13, *)
public struct RouterView: View {
    @State var router: UINavigationControllerRouter
    
    public init<RootRoute: Route>(root: RootRoute) where RootRoute.EnvironmentObjectDependency == VoidObservableObject {
        self._router = State(wrappedValue: UINavigationControllerRouter(root: root))
    }
    
    public init<RootRoute: Route>(root: RootRoute, dependency: RootRoute.EnvironmentObjectDependency) {
        self._router = State(wrappedValue: UINavigationControllerRouter(root: root, dependency))
    }
    
    public var body: some View {
        UINavigationControllerRouterView(router: router)
    }
}
