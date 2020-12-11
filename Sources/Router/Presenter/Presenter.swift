import SwiftUI

@available(iOS 13, macOS 10.15, *)
public protocol Presenter {
    associatedtype Body: View
    var replacesParent: Bool { get }
    
    func body(from parent: AnyView, to destination: AnyView) -> Body
}

@available(iOS 13, macOS 10.15, *)
public struct DestinationPresenter: Presenter {
    public let replacesParent = false
    
    public init() {}
    
    public func body(from parent: AnyView, to destination: AnyView) -> some View {
        destination
    }
}

@available(iOS 13, macOS 10.15, *)
public struct SheetPresenter: Presenter {
    public let replacesParent = true
    
    public init() {}
    
    public func body(from parent: AnyView, to destination: AnyView) -> some View {
        parent.sheet(isPresented: .constant(true), content: { destination })
    }
}

@available(iOS 13, macOS 10.15, *)
public struct AnyPresenter: Presenter {
    private var _replacesParent: () -> Bool
    private var _body: (AnyView, AnyView) -> AnyView
    
    public init<P: Presenter>(_ presenter: P) {
        self._replacesParent = { presenter.replacesParent }
        self._body = { AnyView(presenter.body(from: $0, to: $1)) }
    }
    
    public func body(from parent: AnyView, to destination: AnyView) -> AnyView {
        _body(parent, destination)
    }
    
    public var replacesParent: Bool { _replacesParent() }
}
