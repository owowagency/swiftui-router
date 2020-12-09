import SwiftUI

/// A view that controls routing to a given destination.
@available(iOS 13, *)
public struct RouterLink<Label: View>: View {
    @EnvironmentObject private var router: Router
    private var destination: AnyRoute
    private var label: Label
    
    public init(to destination: AnyRoute, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }
    
    public var body: some View {
        Button(action: navigate) { label }
    }
    
    private func navigate() {
        fatalError("TODO")
    }
}
