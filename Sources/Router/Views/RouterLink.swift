import SwiftUI

/// A view that controls routing to a given destination.
@available(iOS 13, *)
public struct RouterLink<Label: View, Target: Route>: View {
    @Environment(\.router) private var router
    @Environment(\.self) private var environment
    
    @usableFromInline
    var target: Target
    
    @usableFromInline
    var label: Label
    
    @inlinable
    public init(to destination: Destination<Target>, @ViewBuilder label: () -> Label) {
        self.target = destination.route
        self.label = label()
    }
    
    public var body: some View {
        Button(action: navigate) { label }
    }
    
    private func navigate() {
        guard let router = router else {
            preconditionFailure("RouterLink needs to be used in a router context")
        }
        
        router.navigate(to: target, environment: self.environment)
    }
}
