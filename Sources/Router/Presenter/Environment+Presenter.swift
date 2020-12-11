import SwiftUI

@available(iOS 13, macOS 10.15, *)
fileprivate struct PresenterEnvironmentKey: EnvironmentKey {
    typealias Value = AnyPresenter
    
    static let defaultValue = AnyPresenter(DestinationPresenter())
}

@available(iOS 13, macOS 10.15, *)
extension EnvironmentValues {
    var presenter: AnyPresenter {
        get {
            self[PresenterEnvironmentKey.self]
        }
        set {
            self[PresenterEnvironmentKey.self] = newValue
        }
    }
}

@available(iOS 13, macOS 10.15, *)
extension View {
    public func routePresenter<P: Presenter>(_ presenter: P) -> some View {
        environment(\.presenter, AnyPresenter(presenter))
    }
}
