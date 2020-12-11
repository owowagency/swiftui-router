import SwiftUI

@available(iOS 13, macOS 10.15, *)
fileprivate struct RouterKey: EnvironmentKey {
    typealias Value = Router?
    
    static var defaultValue: Router? = nil
}

@available(iOS 13, macOS 10.15, *)
public extension EnvironmentValues {
    var router: Router? {
        get {
            self[RouterKey.self]
        }
        set {
            self[RouterKey.self] = newValue
        }
    }
}
