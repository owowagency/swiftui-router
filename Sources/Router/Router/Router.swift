import SwiftUI

@available(iOS 13, macOS 10.15, *)
public protocol Router {
    func navigate<Target: Presentor>(with presentor: Target.Type, parent: Target.Parent, child: Target.Child)
    func replaceRoot<Target: Presentor>(with presentor: Target.Type, parent: Target.Parent, child: Target.Child)
}
