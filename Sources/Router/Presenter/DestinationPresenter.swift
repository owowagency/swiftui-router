import SwiftUI

/// A presenter that presents a destination only.
@available(iOS 13, macOS 10.15, *)
public struct DestinationPresenter: Presenter {
    public var replacesParent: Bool
    
    public init(replacesParent: Bool = false) {
        self.replacesParent = replacesParent
    }
    
    public func body(with context: PresentationContext) -> some View {
        context.destination
    }
}
