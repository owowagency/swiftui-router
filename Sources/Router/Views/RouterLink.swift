import SwiftUI

/// A view that controls routing to a given destination.
@available(iOS 13, macOS 10.15, *)
public struct RouterLink<Label: View, P: Presentor>: View {
    @Environment(\.router) private var router
    
    @usableFromInline
    var parent: P.Parent
    
    @usableFromInline
    var child: P.Child
    
    @usableFromInline
    var label: Label
    
    /// Creates an instance that navigates to `destination`.
    /// - Parameters:
    ///   - destination: The navigation target route.
    ///   - label: A label describing the link.
    @inlinable
    public init<Target: Route>(
        to destination: Target,
        @ViewBuilder label: () -> Label
    ) where P == ParentPresentor<Target> {
        self.parent = destination
        self.child = VoidRoute()
        self.label = label()
    }
    
    public var body: some View {
        Button(action: navigate) { label }
    }
    
    private func navigate() {
        guard let router = router else {
            preconditionFailure("RouterLink needs to be used in a router context")
        }
        
        router.navigate(
            with: P.self,
            parent: parent,
            child: child
        )
    }
}
