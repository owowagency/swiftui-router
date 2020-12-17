import SwiftUI

/// A view that controls routing to a given destination.
@available(iOS 13, macOS 10.15, *)
public struct RouterLink<Label: View, Target: EnvironmentDependentRoute>: View {
    @Environment(\.router) private var router
    @EnvironmentObject private var dependency: Target.EnvironmentObjectDependency
    @Environment(\.presenter) private var presenter
    @Environment(\.routeViewId) private var source
    
    @usableFromInline
    var target: Target
    
    @usableFromInline
    var label: Label
    
    @usableFromInline
    var replaceRoot: Bool
    
    /// Creates an instance that navigates to `destination`.
    /// - Parameters:
    ///   - destination: The navigation target route.
    ///   - label: A label describing the link.
    ///   - replaceRoot: When set to `true`, the link will use the `replaceRoot` router method instead of `navigate`
    @inlinable
    public init(to destination: Target, replaceRoot: Bool = false, @ViewBuilder label: () -> Label) {
        self.target = destination
        self.replaceRoot = replaceRoot
        self.label = label()
    }
    
    public var body: some View {
        Button(action: navigate) { label }
    }
    
    private func navigate() {
        guard let router = router else {
            preconditionFailure("RouterLink needs to be used in a router context")
        }
        
        if replaceRoot {
            router.replaceRoot(with: target, dependency, using: presenter)
        } else {
            router.navigate(to: target, dependency, using: presenter, source: source)
        }
    }
}
