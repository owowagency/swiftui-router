import SwiftUI

/// When a route is presented, the presenting router is responsible for assigning it a `RouteViewIdentifier`.
/// You need a route view identifier to refer to routed views after their initial presentation.
///
/// You can read the route view identifier of the current route using the environment modifier.
///
/// `@Environment(\.routeViewId) var routeViewIdentifier`
public struct RouteViewIdentifier: Hashable {
    public static let none = RouteViewIdentifier(id: 0)
    private static var id = 1
    let id: Int
    
    private init(id: Int) {
        self.id = id
    }
    
    /// Generates a new route view identifier.
    public init() {
        self.id = Self.id
        Self.id += 1
    }
}

// MARK: - Environment

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
