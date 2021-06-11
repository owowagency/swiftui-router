#if canImport(AppKit)
import SwiftUI

public struct MacRouterView: NSViewControllerRepresentable {
    public typealias NSViewControllerType = NSHostingController<AnyView>
    
    public let router: MacRouter
    
    public init(router: MacRouter) {
        self.router = router
    }
    
    public func makeNSViewController(context: Context) -> NSHostingController<AnyView> {
        router.hostingController
    }
    
    public func updateNSViewController(_ nsViewController: NSHostingController<AnyView>, context: Context) { }
}
#endif
