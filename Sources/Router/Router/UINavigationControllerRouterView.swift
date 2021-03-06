import SwiftUI

@available(iOS 13, macOS 10.15, *)
public struct UINavigationControllerRouterView: UIViewControllerRepresentable {
    public let router: UINavigationControllerRouter
    
    public init(router: UINavigationControllerRouter) {
        self.router = router
    }
    
    public func makeUIViewController(context: Context) -> UINavigationController {
        router.navigationController
    }
    
    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
