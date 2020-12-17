import SwiftUI

@available(iOS 13, macOS 10.15, *)
public struct AnyPresenter: Presenter {
    private var _replacesParent: () -> Bool
    private var _body: (PresentationContext) -> AnyView
    
    public init<P: Presenter>(_ presenter: P) {
        self._replacesParent = { presenter.replacesParent }
        self._body = { AnyView(presenter.body(with: $0)) }
    }
    
    public func body(with context: PresentationContext) -> AnyView {
        _body(context)
    }
    
    public var replacesParent: Bool { _replacesParent() }
}

