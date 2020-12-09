import SwiftUI

@available(iOS 13, *)
@dynamicMemberLookup
public struct Destination<Target: Route> {
    public var route: Target
    
    public static subscript(dynamicMember keyPath: KeyPath<Routes, Target>) -> Destination {
        Destination(route: Routes()[keyPath: keyPath])
    }
}
