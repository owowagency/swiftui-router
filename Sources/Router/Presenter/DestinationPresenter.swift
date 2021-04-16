import SwiftUI

/// A presenter that presents a destination only.
@available(iOS 13, macOS 10.15, *)
public struct DestinationPresenter: Presenter {
    public var presentationMode: RoutePresentationMode
    
    public init(presentationMode: RoutePresentationMode = .normal) {
        self.presentationMode = presentationMode
    }
    
    public func body(with context: PresentationContext) -> some View {
        context.destination
    }
}
