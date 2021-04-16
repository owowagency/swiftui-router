import SwiftUI

/// A presenter that presents content as a sheet.
@available(iOS 13, macOS 10.15, *)
public struct SheetPresenter: Presenter {
    public let presentationMode: RoutePresentationMode = .sibling
    
    let providesRouter: Bool
    
    public init(providesRouter: Bool = true) {
        self.providesRouter = providesRouter
    }
    
    @ViewBuilder
    public func body(with context: PresentationContext) -> some View {
        context.parent
            .sheet(isPresented: context.$isPresented) {
                if providesRouter {
                    context.makeDestinationRouter()
                } else {
                    context.destination
                }
            }
    }
}
