import SwiftUI

/// A view that controls routing to a given destination.
@available(iOS 13, *)
public struct RouterLink<Label: View, Target: Route>: View {
    @Environment(\.router) private var router
    @EnvironmentObject private var dependency: Target.EnvironmentObjectDependency
    
    @usableFromInline
    var target: Target
    
    @usableFromInline
    var label: Label
    
    /// Creates an instance that navigates to `destination`.
    /// - Parameters:
    ///   - destination: The navigation target route.
    ///   - label: A label describing the link.
    @inlinable
    public init(to destination: Target, @ViewBuilder label: () -> Label) {
        self.target = destination
        self.label = label()
    }
    
    public var body: some View {
        Button(action: navigate) { label }
    }
    
    private func navigate() {
        guard let router = router else {
            preconditionFailure("RouterLink needs to be used in a router context")
        }
        
        router.navigate(to: target, dependency)
    }
}
