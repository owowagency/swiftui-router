import SwiftUI

@available(iOS 13, macOS 10.15, *)
struct RouteViewIdView<Content: View>: View, Equatable {
    var routeViewId: RouteViewIdentifier
    var content: Content
    
    var body: some View {
        content
            .environment(\.routeViewId, routeViewId)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.routeViewId == rhs.routeViewId
    }
}
