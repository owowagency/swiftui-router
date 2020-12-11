import SwiftUI

@available(iOS 13, macOS 10.15, *)
fileprivate struct RouteViewIdentifierKey: EnvironmentKey {
    typealias Value = RouteViewIdentifier
    
    static var defaultValue: RouteViewIdentifier = .none
}

@available(iOS 13, macOS 10.15, *)
public extension EnvironmentValues {
    var routeViewId: RouteViewIdentifier {
        get {
            self[RouteViewIdentifierKey.self]
        }
        set {
            self[RouteViewIdentifierKey.self] = newValue
        }
    }
}
